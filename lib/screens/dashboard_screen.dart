import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:enquiry_app/main.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:enquiry_app/providers/riverpod_providers.dart';
import 'package:enquiry_app/utils/api_debug_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:enquiry_app/chartfile/chat_screen.dart';
import 'package:enquiry_app/widgets/reply_form_dialog.dart';

import 'package:enquiry_app/chartfile/getbulk.dart';
import 'package:enquiry_app/chartfile/getenq.dart';
import 'package:enquiry_app/chartfile/getsector.dart';
import 'package:enquiry_app/chartfile/chat_threads_screen.dart';
import 'package:enquiry_app/screens/chats_list_screen.dart';

import 'package:enquiry_app/screens/profile_screen.dart';
import 'package:enquiry_app/screens/settings_screen.dart';
import 'package:enquiry_app/screens/security_screen.dart';
import 'package:enquiry_app/screens/login_screen.dart';
import 'package:enquiry_app/screens/others_category_screen.dart';
import 'package:enquiry_app/utils/sharing_intent_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:enquiry_app/widgets/multi_select_category_dropdown.dart';
import 'package:enquiry_app/modules/finance/finance_calculator_hub_screen.dart';

import 'package:enquiry_app/services/storage_service.dart';
import 'package:enquiry_app/services/auth_service.dart';
import 'package:enquiry_app/services/biometric_service.dart';
import 'package:enquiry_app/theme/app_theme.dart';
import 'package:enquiry_app/utils/constants.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _localAvatarPath;
  String? _locationName;
  String? _userName;

  int? _bulkOrdersCount;
  int? _enquiriesCount;
  int? _sectorsCount;
  bool _isLoadingCounts = false;

  String _timeString = "";
  String _dateString = "";
  Timer? _timeTimer;

  List<dynamic> _dashboardOrders = [];
  List<dynamic> _dashboardEnquiries = [];
  List<dynamic> _dashboardSectors = [];
  final Map<int, List<dynamic>> _chatMessages = {};
  bool _isFeedLoading = false;
  String _feedType = "orders"; // "orders", "enquiries", or "sectors"
  String _feedFilter = "all"; // "all", "today", "unreplied", "received", "sent"
  String _searchQuery = "";

  final ScrollController _scrollController = ScrollController();
  int _ordersPage = 1;
  bool _ordersHasMore = true;
  int _enquiriesPage = 1;
  bool _enquiriesHasMore = true;
  int _sectorsPage = 1;
  bool _sectorsHasMore = true;
  bool _isLoadingMore = false;

  int? _lastEnquiryId;
  int? _lastBulkOrderId;
  int? _lastSectorId;
  bool _isFirstLoad = true;
  bool _isAutoRefreshing = false;
  bool _isSelectionMode = false;
  final Set<int> _selectedItemIds = {};
  List<String> _selectedOrdersCategories = [];
  List<String> _selectedEnquiriesCategories = [];
  List<String> _selectedSectorsCategories = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _updateTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
    _loadData();
    SharingIntentHandler.checkAndProcessPending();
  }


  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadNextPageForActiveFeed();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _timeTimer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final period = now.hour >= 12 ? "PM" : "AM";
    final timeStr = "${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} $period";
    final dateStr = "${now.day} ${_getMonthName(now.month)} ${now.year}";
    if (mounted) {
      setState(() {
        _timeString = timeStr;
        _dateString = dateStr;
      });
    }
  }

  String _getMonthName(int month) {
    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }

  StorageService? _storageInstance;

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final storageService = ref.read(storageServiceProvider);
    _storageInstance = storageService;
    if (storageService.userCategories.isEmpty && storageService.userId.isNotEmpty) {
      try {
        final authService = ref.read(authServiceProvider);
        await authService.fetchAndStoreUserCategories(storageService.userId);
      } catch (_) {}
    }
    setState(() {
      _localAvatarPath = prefs.getString('persistent_profile_photo_path');
      _locationName = prefs.getString('user_location_name');
      _userName = storageService.userName;
    });
    await _fetchCounts();
    await _fetchFeedData();
  }

  Future<void> _autoRefreshData() async {
    if (!mounted || _isAutoRefreshing) return;
    _isAutoRefreshing = true;
    try {
      await _fetchCounts(silent: true);
      await _fetchFeedData(silent: true);
    } catch (_) {
    } finally {
      _isAutoRefreshing = false;
    }
  }

  Future<void> _fetchCounts({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _isLoadingCounts = true;
      });
    }
    // 1. Fetch Bulk Orders Count
    try {
      final resBulk = await ApiDebugLogger.httpClient.get(
        Uri.parse("https://bulk.srivagroups.in/api/bulk-orders?limit=1"),
      ).timeout(const Duration(seconds: 5));
      if (resBulk.statusCode == 200) {
        final decoded = jsonDecode(resBulk.body);
        if (decoded is Map && decoded.containsKey('total')) {
          _bulkOrdersCount = int.tryParse(decoded['total'].toString());
        }
      }
    } catch (e) {
      print("[Sound] Error fetching bulk count: $e");
    }

    // 2. Fetch Enquiries Count
    try {
      final resEnq = await ApiDebugLogger.httpClient.get(
        Uri.parse("https://bulk.srivagroups.in/api/enquiries?limit=1"),
      ).timeout(const Duration(seconds: 5));
      if (resEnq.statusCode == 200) {
        final decoded = jsonDecode(resEnq.body);
        if (decoded is Map && decoded.containsKey('total')) {
          _enquiriesCount = int.tryParse(decoded['total'].toString());
        } else if (decoded is Map && decoded['data'] is List) {
          _enquiriesCount = (decoded['data'] as List).length;
        } else if (decoded is List) {
          _enquiriesCount = decoded.length;
        }
      }
    } catch (e) {
      print("[Sound] Error fetching enquiries count: $e");
    }

    // 3. Fetch Sectors Count
    try {
      final resSec = await ApiDebugLogger.httpClient.get(
        Uri.parse("https://bulk.srivagroups.in/api/product?limit=1"),
      ).timeout(const Duration(seconds: 5));
      if (resSec.statusCode == 200) {
        final decoded = jsonDecode(resSec.body);
        if (decoded is Map && decoded.containsKey('total')) {
          _sectorsCount = int.tryParse(decoded['total'].toString());
        } else if (decoded is Map && decoded['data'] is List) {
          _sectorsCount = (decoded['data'] as List).length;
        } else if (decoded is List) {
          _sectorsCount = decoded.length;
        }
      }
    } catch (e) {
      print("[Sound] Error fetching sectors count: $e");
    }

    if (mounted) {
      setState(() {
        _isLoadingCounts = false;
      });
    }
  }

  void _checkNewRecordsAndPlaySound() async {
    int getMaxId(List<dynamic> items) {
      int maxId = 0;
      for (var item in items) {
        if (item is Map) {
          final idVal = item["id"];
          final id = idVal is int ? idVal : int.tryParse(idVal.toString()) ?? 0;
          if (id > maxId) {
            maxId = id;
          }
        }
      }
      return maxId;
    }

    final maxOrder = getMaxId(_dashboardOrders);
    final maxEnquiry = getMaxId(_dashboardEnquiries);
    final maxSector = getMaxId(_dashboardSectors);

    if (_isFirstLoad) {
      _lastBulkOrderId = maxOrder;
      _lastEnquiryId = maxEnquiry;
      _lastSectorId = maxSector;
      _isFirstLoad = false;
      return;
    }

    bool hasNew = false;
    bool hasNewToday = false;

    if (maxOrder > (_lastBulkOrderId ?? 0)) {
      for (var item in _dashboardOrders) {
        if (item is Map) {
          final idVal = item["id"];
          final id = idVal is int ? idVal : int.tryParse(idVal.toString()) ?? 0;
          if (id > (_lastBulkOrderId ?? 0)) {
            if (_isToday(item['submittedAt'] ?? item['submitted_at'])) {
              hasNewToday = true;
            }
          }
        }
      }
      hasNew = true;
      _lastBulkOrderId = maxOrder;
    }

    if (maxEnquiry > (_lastEnquiryId ?? 0)) {
      for (var item in _dashboardEnquiries) {
        if (item is Map) {
          final idVal = item["id"];
          final id = idVal is int ? idVal : int.tryParse(idVal.toString()) ?? 0;
          if (id > (_lastEnquiryId ?? 0)) {
            if (_isToday(item['submittedAt'] ?? item['submitted_at'] ?? item['created_at'])) {
              hasNewToday = true;
            }
          }
        }
      }
      hasNew = true;
      _lastEnquiryId = maxEnquiry;
    }

    if (maxSector > (_lastSectorId ?? 0)) {
      for (var item in _dashboardSectors) {
        if (item is Map) {
          final idVal = item["id"];
          final id = idVal is int ? idVal : int.tryParse(idVal.toString()) ?? 0;
          if (id > (_lastSectorId ?? 0)) {
            if (_isToday(item['submittedAt'] ?? item['created_at'])) {
              hasNewToday = true;
            }
          }
        }
      }
      hasNew = true;
      _lastSectorId = maxSector;
    }

    print("Current Max ID: Bulk Orders=$maxOrder, Enquiries=$maxEnquiry, Sectors=$maxSector");
    print("Last Seen ID: Bulk Orders=$_lastBulkOrderId, Enquiries=$_lastEnquiryId, Sectors=$_lastSectorId");
    print("Should Play = ${hasNewToday.toString().toUpperCase()}");

    if (hasNewToday) {
      final prefs = await SharedPreferences.getInstance();
      final soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
      print("[Sound] soundEnabled preference: $soundEnabled");
      if (soundEnabled) {
        print("[Sound] Executing playNotificationSound()");
        ref.read(notificationSoundServiceProvider).playNotificationSound();
      }
    }
  }

  Future<void> _fetchFeedData({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _isFeedLoading = true;
        _ordersPage = 1;
        _ordersHasMore = true;
        _enquiriesPage = 1;
        _enquiriesHasMore = true;
        _sectorsPage = 1;
        _sectorsHasMore = true;
      });
    } else {
      _ordersPage = 1;
      _ordersHasMore = true;
      _enquiriesPage = 1;
      _enquiriesHasMore = true;
      _sectorsPage = 1;
      _sectorsHasMore = true;
    }

    // 1. Fetch Bulk Orders
    try {
      final resBulk = await ApiDebugLogger.httpClient.get(
        Uri.parse("https://bulk.srivagroups.in/api/bulk-orders?limit=10&page=1"),
      ).timeout(const Duration(seconds: 5));
      if (resBulk.statusCode == 200) {
        final decoded = jsonDecode(resBulk.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }
        
        _dashboardOrders = list.map((x) {
          if (x is Map) {
            final item = Map<String, dynamic>.from(x);
            item['bulkOrderID'] ??= item['id'] ?? item['bulk_order_id'];
            item['specialInstructions'] ??= item['special_instructions'];
            item['company'] ??= item['company_name'];
            item['product'] ??= item['product_name'];
            item['deliveryDate'] ??= item['preferred_delivery_date'];
            item['submittedAt'] ??= item['submitted_at'];
            item['pdfPath'] ??= item['pdf_path'] ?? item['bulk_order_pdf'] ?? item['bulk_order_ref_file'];
            return item;
          }
          return x;
        }).toList();
        
        _dashboardOrders.sort((a, b) {
          final idA = a["id"] is int ? a["id"] : int.tryParse(a["id"].toString()) ?? 0;
          final idB = b["id"] is int ? b["id"] : int.tryParse(b["id"].toString()) ?? 0;
          return idB.compareTo(idA);
        });

        if (list.length < 10) {
          _ordersHasMore = false;
        } else {
          _ordersPage = 2;
        }
      }
    } catch (e) {
      print("[Sound] Error fetching bulk orders: $e");
    }

    // 2. Fetch Enquiries
    try {
      final resEnq = await ApiDebugLogger.httpClient.get(
        Uri.parse("https://bulk.srivagroups.in/api/enquiries?limit=10&page=1"),
      ).timeout(const Duration(seconds: 5));
      if (resEnq.statusCode == 200) {
        final decoded = jsonDecode(resEnq.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }
        
        _dashboardEnquiries = list.map((x) {
          if (x is Map) {
            final item = Map<String, dynamic>.from(x);
            item['company'] ??= item['company_name'];
            item['product'] ??= item['product_name'];
            item['submittedAt'] ??= item['submitted_at'];
            return item;
          }
          return x;
        }).toList();
        
        _dashboardEnquiries.sort((a, b) {
          final idA = a["id"] is int ? a["id"] : int.tryParse(a["id"].toString()) ?? 0;
          final idB = b["id"] is int ? b["id"] : int.tryParse(b["id"].toString()) ?? 0;
          return idB.compareTo(idA);
        });

        if (list.length < 10) {
          _enquiriesHasMore = false;
        } else {
          _enquiriesPage = 2;
        }
      }
    } catch (e) {
      print("[Sound] Error fetching enquiries: $e");
    }

    // 3. Fetch Sectors
    try {
      final resSec = await ApiDebugLogger.httpClient.get(
        Uri.parse("https://bulk.srivagroups.in/api/product?limit=10&page=1"),
      ).timeout(const Duration(seconds: 5));
      if (resSec.statusCode == 200) {
        final decoded = jsonDecode(resSec.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }
        
        _dashboardSectors = list.map((x) {
          if (x is Map) {
            final item = Map<String, dynamic>.from(x);
            item['submittedAt'] ??= item['date'] ?? item['created_at'];
            item['product'] ??= item['title'] ?? item['name'];
            item['company'] ??= item['category'] ?? item['website_name'];
            return item;
          }
          return x;
        }).toList();
        
        _dashboardSectors.sort((a, b) {
          final idA = a["id"] is int ? a["id"] : int.tryParse(a["id"].toString()) ?? 0;
          final idB = b["id"] is int ? b["id"] : int.tryParse(b["id"].toString()) ?? 0;
          return idB.compareTo(idA);
        });

        if (list.length < 10) {
          _sectorsHasMore = false;
        } else {
          _sectorsPage = 2;
        }
      }
    } catch (e) {
      print("[Sound] Error fetching sectors: $e");
    }

    // Post-fetch notification checks
    try {
      _checkNewRecordsAndPlaySound();
      _fetchChatStatusesInBackground();
    } catch (e) {
      print("[Sound] Error in post-fetch: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFeedLoading = false;
        });
      }
    }
  }


  Future<void> _fetchChatStatusesForItems(List<dynamic> items) async {
    final chunkSize = 10;
    for (var i = 0; i < items.length; i += chunkSize) {
      if (!mounted) return;
      final chunk = items.sublist(i, i + chunkSize > items.length ? items.length : i + chunkSize);
      
      await Future.wait(chunk.map((item) async {
        if (item is! Map) return;
        final id = item["id"] is int ? item["id"] : int.tryParse(item["id"].toString()) ?? 0;
        if (id == 0) return;
        
        try {
          final isOrder = _dashboardOrders.any((o) => o["id"] == id);
          final isEnq = _dashboardEnquiries.any((e) => e["id"] == id);
          final module = isOrder ? "bulk_order" : (isEnq ? "enquiry" : "product");
          var url = "https://whatsapp.srivagroups.in/conversation.php?module=$module&reference_id=$id";
          var res;
          try {
            res = await ApiDebugLogger.httpClient.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
            if (res.statusCode != 200) {
              throw Exception("Not 200");
            }
          } catch (_) {
            url = "https://bulk.srivagroups.in/api/messages/$module/$id";
            res = await ApiDebugLogger.httpClient.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
          }
          if (res.statusCode == 200) {
            final decoded = jsonDecode(res.body);
            List<dynamic> msgs = [];
            if (decoded is List) {
              msgs = decoded;
            } else if (decoded is Map && decoded['messages'] is List) {
              msgs = decoded['messages'];
            }
            if (mounted) {
              setState(() {
                _chatMessages[id] = msgs;
              });
            }
          }
        } catch (_) {}
      }));
    }
  }

  Future<void> _fetchChatStatusesInBackground() async {
    final List<dynamic> allItems = [..._dashboardOrders, ..._dashboardEnquiries, ..._dashboardSectors];
    await _fetchChatStatusesForItems(allItems);
  }

  Future<void> _loadNextPageForActiveFeed() async {
    if (_isLoadingMore) return;
    
    if (_feedType == "orders") {
      if (!_ordersHasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
      try {
        final res = await ApiDebugLogger.httpClient.get(
          Uri.parse("https://bulk.srivagroups.in/api/bulk-orders?limit=10&page=$_ordersPage"),
        ).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          List<dynamic> list = [];
          if (decoded is List) {
            list = decoded;
          } else if (decoded is Map && decoded['data'] is List) {
            list = decoded['data'];
          }
          
          if (list.isEmpty) {
            setState(() {
              _ordersHasMore = false;
            });
          } else {
            final mapped = list.map((x) {
              if (x is Map) {
                final item = Map<String, dynamic>.from(x);
                item['bulkOrderID'] ??= item['id'] ?? item['bulk_order_id'];
                item['specialInstructions'] ??= item['special_instructions'];
                item['company'] ??= item['company_name'];
                item['product'] ??= item['product_name'];
                item['deliveryDate'] ??= item['preferred_delivery_date'];
                item['submittedAt'] ??= item['submitted_at'];
                item['pdfPath'] ??= item['pdf_path'] ?? item['bulk_order_pdf'] ?? item['bulk_order_ref_file'];
                return item;
              }
              return x;
            }).toList();
            
            setState(() {
              _dashboardOrders.addAll(mapped);
              _dashboardOrders.sort((a, b) {
                final idA = a["id"] is int ? a["id"] : int.tryParse(a["id"].toString()) ?? 0;
                final idB = b["id"] is int ? b["id"] : int.tryParse(b["id"].toString()) ?? 0;
                return idB.compareTo(idA);
              });
              _ordersPage++;
              if (list.length < 10) {
                _ordersHasMore = false;
              }
            });
            _fetchChatStatusesForItems(mapped);
          }
        }
      } catch (e) {
        print("Error loading more orders: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      }
    } else if (_feedType == "enquiries") {
      if (!_enquiriesHasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
      try {
        final res = await ApiDebugLogger.httpClient.get(
          Uri.parse("https://bulk.srivagroups.in/api/enquiries?limit=10&page=$_enquiriesPage"),
        ).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          List<dynamic> list = [];
          if (decoded is List) {
            list = decoded;
          } else if (decoded is Map && decoded['data'] is List) {
            list = decoded['data'];
          }
          
          if (list.isEmpty) {
            setState(() {
              _enquiriesHasMore = false;
            });
          } else {
            final mapped = list.map((x) {
              if (x is Map) {
                final item = Map<String, dynamic>.from(x);
                item['company'] ??= item['company_name'];
                item['product'] ??= item['product_name'];
                item['submittedAt'] ??= item['submitted_at'];
                return item;
              }
              return x;
            }).toList();
            
            setState(() {
              _dashboardEnquiries.addAll(mapped);
              _dashboardEnquiries.sort((a, b) {
                final idA = a["id"] is int ? a["id"] : int.tryParse(a["id"].toString()) ?? 0;
                final idB = b["id"] is int ? b["id"] : int.tryParse(b["id"].toString()) ?? 0;
                return idB.compareTo(idA);
              });
              _enquiriesPage++;
              if (list.length < 10) {
                _enquiriesHasMore = false;
              }
            });
            _fetchChatStatusesForItems(mapped);
          }
        }
      } catch (e) {
        print("Error loading more enquiries: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      }
    } else if (_feedType == "sectors") {
      if (!_sectorsHasMore) return;
      setState(() {
        _isLoadingMore = true;
      });
      try {
        final res = await ApiDebugLogger.httpClient.get(
          Uri.parse("https://bulk.srivagroups.in/api/product?limit=10&page=$_sectorsPage"),
        ).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          List<dynamic> list = [];
          if (decoded is List) {
            list = decoded;
          } else if (decoded is Map && decoded['data'] is List) {
            list = decoded['data'];
          }
          
          if (list.isEmpty) {
            setState(() {
              _sectorsHasMore = false;
            });
          } else {
            final mapped = list.map((x) {
              if (x is Map) {
                final item = Map<String, dynamic>.from(x);
                item['submittedAt'] ??= item['date'] ?? item['created_at'];
                item['product'] ??= item['title'] ?? item['name'];
                item['company'] ??= item['category'] ?? item['website_name'];
                return item;
              }
              return x;
            }).toList();
            
            setState(() {
              _dashboardSectors.addAll(mapped);
              _dashboardSectors.sort((a, b) {
                final idA = a["id"] is int ? a["id"] : int.tryParse(a["id"].toString()) ?? 0;
                final idB = b["id"] is int ? b["id"] : int.tryParse(b["id"].toString()) ?? 0;
                return idB.compareTo(idA);
              });
              _sectorsPage++;
              if (list.length < 10) {
                _sectorsHasMore = false;
              }
            });
            _fetchChatStatusesForItems(mapped);
          }
        }
      } catch (e) {
        print("Error loading more sectors: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      }
    }
  }

  bool _isToday(dynamic dateVal) {
    if (dateVal == null) return false;
    try {
      final dateStr = dateVal.toString();
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (_) {
      return false;
    }
  }

  String _getCategoryFromItem(dynamic x) {
    if (x is! Map) return "";
    final keys = ['category', 'categories', 'category_name', 'Category', 'company', 'website_name'];
    for (final key in keys) {
      if (x.containsKey(key) && x[key] != null) {
        final val = x[key];
        if (val is Map) {
          final subVal = val['name'] ?? val['title'] ?? val['label'];
          if (subVal != null && subVal.toString().trim().isNotEmpty) {
            return subVal.toString().trim();
          }
        } else if (val is List) {
          if (val.isNotEmpty) {
            final first = val.first;
            if (first is Map) {
              final subVal = first['name'] ?? first['title'] ?? first['label'];
              if (subVal != null && subVal.toString().trim().isNotEmpty) {
                return subVal.toString().trim();
              }
            } else if (first != null) {
              return first.toString().trim();
            }
          }
        } else {
          final str = val.toString().trim();
          if (str.isNotEmpty && str.toLowerCase() != "null" && str != "-") {
            return str;
          }
        }
      }
    }
    return "";
  }

  List<String> get _currentFeedCategories {
    final items = _feedType == "orders"
        ? _dashboardOrders
        : (_feedType == "enquiries" ? _dashboardEnquiries : _dashboardSectors);
    final cats = items
        .map((x) => _getCategoryFromItem(x))
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  int get todayBulkOrdersCount {
    return _dashboardOrders.where((o) => _isToday(o['submittedAt'] ?? o['submitted_at'])).length;
  }

  int get todayEnquiriesCount {
    return _dashboardEnquiries.where((e) => _isToday(e['submittedAt'] ?? e['submitted_at'] ?? e['created_at'])).length;
  }

  int get todaySectorsCount {
    return _dashboardSectors.where((s) => _isToday(s['submittedAt'] ?? s['date'] ?? s['created_at'])).length;
  }

  Future<void> _launchCall(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final url = Uri.parse("tel:${phone.trim()}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchEmail(String? email, String subject) async {
    if (email == null || email.trim().isEmpty) return;
    final url = Uri.parse("mailto:${email.trim()}?subject=${Uri.encodeComponent(subject)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final storageService = ref.read(storageServiceProvider);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: isDarkMode ? const Color(0xFF151B2C) : Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 38,
                    color: Colors.redAccent,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'Terminate Session?',
                  style: GoogleFonts.outfit(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Logging out will end your current secure session clearance. You will need to re-verify credentials next time.',
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 28.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.15),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Stay Secure',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final biometricService = ref.read(biometricServiceProvider);
                          final authService = ref.read(authServiceProvider);

                          Navigator.pop(dialogContext);

                          if (storageService.askBiometricsBeforeLogout) {
                            final result = await biometricService.authenticate(
                              reason:
                                  'Verify identity to authorize session termination',
                            );
                            if (!result.success) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.lock_rounded,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Logout Aborted: ${result.message}',
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                          }

                          print("========== LOGOUT DEBUG (BEFORE) ==========");
                          await authService.logout();

                          final prefsInstance =
                              await SharedPreferences.getInstance();
                          await prefsInstance.remove('auth_token');

                          print("========== LOGOUT DEBUG ==========");
                          print("TOKEN REMOVED");
                          print("USER LOGGED OUT");
                          print("NAVIGATING TO LOGIN PAGE");
                          print("=================================");

                          if (!mounted) return;

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'End Session',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final displayName = (_userName != null && _userName!.isNotEmpty) ? _userName! : "";

    final items = _feedType == "orders"
        ? _dashboardOrders
        : (_feedType == "enquiries" ? _dashboardEnquiries : _dashboardSectors);
    final filtered = items.where((item) {
      if (item is! Map) return false;

      // Storage Category Filter
      final storage = _storageInstance ?? StorageService.currentInstance;
      if (!storage.isCategoryAllowed(item)) {
        return false;
      }

      // Category filter
      final activeSelected = _feedType == "orders"
          ? _selectedOrdersCategories
          : (_feedType == "enquiries" ? _selectedEnquiriesCategories : _selectedSectorsCategories);
      if (activeSelected.isNotEmpty) {
        final cat = _getCategoryFromItem(item);
        if (!activeSelected.contains(cat)) {
          return false;
        }
      }

      final name = (item["name"] ?? "").toString().toLowerCase();
      final company = (item["company"] ?? "").toString().toLowerCase();
      final product = (item["product"] ?? "").toString().toLowerCase();
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        if (!name.contains(q) && !company.contains(q) && !product.contains(q)) {
          return false;
        }
      }
      final id = item["id"] is int ? item["id"] : int.tryParse(item["id"].toString()) ?? 0;
      final msgs = _chatMessages[id] ?? [];
      switch (_feedFilter) {
        case "today":
          return _isToday(item['submittedAt'] ?? item['submitted_at'] ?? item['created_at']);
        case "unreplied":
          return msgs.isEmpty || !msgs.any((m) => m["sender"]?.toString().toLowerCase() == "admin");
        case "received":
          return msgs.isNotEmpty && msgs.last["sender"]?.toString().toLowerCase() != "admin";
        case "sent":
          return msgs.isNotEmpty && msgs.any((m) => m["sender"]?.toString().toLowerCase() == "admin");
        default:
          return true;
      }
    }).toList();

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => Scaffold(
        floatingActionButton: (_isSelectionMode && _selectedItemIds.isNotEmpty)
            ? FloatingActionButton.extended(
                onPressed: _showShareOptionsSheet,
                label: Text("Share (${_selectedItemIds.length})"),
                icon: const Icon(Icons.share_rounded),
                backgroundColor: Theme.of(context).colorScheme.primary,
              )
            : null,
        drawer: Drawer(
          backgroundColor: isDarkMode ? const Color(0xFF151B2C) : Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppTheme.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30.r,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage:
                          _localAvatarPath != null &&
                              File(_localAvatarPath!).existsSync()
                          ? FileImage(File(_localAvatarPath!)) as ImageProvider
                          : null,
                      child: _localAvatarPath == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 35.w,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    SizedBox(height: 15.h),
                    Text(
                      "WELCOME",
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        letterSpacing: 2,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),

              ListTile(
                leading: Icon(
                  Icons.inventory_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  "Bulk Order",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const getbuk()),
                  );
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.question_answer_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  "Enquiry",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GetEnquiry()),
                  );
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.business_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  "Sector",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GetById()),
                  );
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.calculate_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  "Finance Calculators",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FinanceCalculatorHubScreen(),
                    ),
                  );
                },
              ),

              const Divider(),

              ListTile(
                leading: Icon(
                  Icons.person_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  "Profile Settings",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                  _loadData();
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  "System Settings",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SettingsScreen(isStandalone: true),
                    ),
                  );
                  _loadData();
                },
              ),

              ListTile(
                leading: Icon(
                  Icons.lock_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  "Lock Screen Options",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecurityScreen(),
                    ),
                  );
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                ),
                title: Text(
                  "Logout",
                  style: GoogleFonts.outfit(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutConfirmation(context);
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: isDarkMode
              ? const Color(0xFF0F172A)
              : const Color(0xFF6366F1),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            "CirCuiT PoInT",
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20.sp,
            ),
          ),
          centerTitle: true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                  _loadData();
                },
                child: CircleAvatar(
                  radius: 18.r,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage:
                      _localAvatarPath != null &&
                          File(_localAvatarPath!).existsSync()
                      ? FileImage(File(_localAvatarPath!)) as ImageProvider
                      : null,
                  child: _localAvatarPath == null
                      ? const Icon(Icons.person, size: 18, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [
                      const Color(0xFF0B0F19),
                      const Color(0xFF111827),
                      const Color(0xFF1F2937),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFEFF6FF),
                      const Color(0xFFE0F2FE),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(24.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, $displayName",
                          style: GoogleFonts.outfit(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w900,
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Welcome back to your control center",
                          style: GoogleFonts.outfit(
                            fontSize: 13.sp,
                            color: isDarkMode
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                          ),
                        ),
                        if (_locationName != null &&
                            _locationName!.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14.r,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _locationName!,
                                style: GoogleFonts.outfit(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Live Clock & Today's Summary Banner
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 20.h),
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [const Color(0xFF312E81), const Color(0xFF1E1B4B)]
                            : [const Color(0xFF4F46E5), const Color(0xFF3730A3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dateString,
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              _timeString,
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          "Today's Overview",
                          style: GoogleFonts.outfit(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _feedType = "orders";
                                    _feedFilter = "today";
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Orders",
                                        style: GoogleFonts.outfit(
                                          fontSize: 10.sp,
                                          color: Colors.white.withOpacity(0.7),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        "$todayBulkOrdersCount Today",
                                        style: GoogleFonts.outfit(
                                          fontSize: 13.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _feedType = "enquiries";
                                    _feedFilter = "today";
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Enquiries",
                                        style: GoogleFonts.outfit(
                                          fontSize: 10.sp,
                                          color: Colors.white.withOpacity(0.7),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        "$todayEnquiriesCount Today",
                                        style: GoogleFonts.outfit(
                                          fontSize: 13.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _feedType = "sectors";
                                    _feedFilter = "today";
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Sectors",
                                        style: GoogleFonts.outfit(
                                          fontSize: 10.sp,
                                          color: Colors.white.withOpacity(0.7),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        "$todaySectorsCount Today",
                                        style: GoogleFonts.outfit(
                                          fontSize: 13.sp,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const OthersCategoryScreen()),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Others",
                                        style: GoogleFonts.outfit(
                                          fontSize: 10.sp,
                                          color: Colors.white.withOpacity(0.7),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "Filter",
                                              style: GoogleFonts.outfit(
                                                fontSize: 13.sp,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 10.r,
                                            color: Colors.white70,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick Actions Control Row
                  Padding(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const GetById()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.business_rounded, size: 18.r, color: const Color(0xFF10B981)),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "Sector Controls",
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SecurityScreen()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.security_rounded, size: 18.r, color: const Color(0xFFF59E0B)),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "Security Setup",
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Chats and Unread Messages Row
                  Padding(
                    padding: EdgeInsets.only(bottom: 24.h),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatsListScreen(),
                          ),
                        ).then((_) {
                          _loadData();
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.forum_rounded,
                                size: 24.r,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Active Chat Threads",
                                    style: GoogleFonts.outfit(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    "Monitor messages & pending customer replies",
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.sp,
                                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                int pendingCount = 0;
                                final allItemIds = [
                                  ..._dashboardOrders.map((o) => o["id"]),
                                  ..._dashboardEnquiries.map((e) => e["id"]),
                                  ..._dashboardSectors.map((s) => s["id"])
                                ];
                                for (var itemId in allItemIds) {
                                  if (itemId == null) continue;
                                  final id = itemId is int ? itemId : int.tryParse(itemId.toString()) ?? 0;
                                  final msgs = _chatMessages[id] ?? [];
                                  if (msgs.isNotEmpty && msgs.last["sender"]?.toString().toLowerCase() != "admin") {
                                    pendingCount++;
                                  }
                                }

                                if (pendingCount > 0) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      "$pendingCount New",
                                      style: GoogleFonts.outfit(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }
                                return Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14.r,
                                  color: Colors.grey.shade400,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Live Workspace / Feed Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Live Feed Control Center",
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 20.r,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: _fetchFeedData,
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  if (_isSelectionMode) ...[
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 10.w),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.red),
                            onPressed: _cancelSelectionMode,
                            tooltip: "Cancel Selection",
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            "${_selectedItemIds.length} Selected",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _selectAllItems(filtered),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                            child: Text(
                              "Select All",
                              style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          TextButton(
                            onPressed: _deselectAllItems,
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                            child: Text(
                              "Clear",
                              style: GoogleFonts.outfit(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],

                  // Segmented Control (Feed Selector: Bulk Orders vs Enquiries vs Sectors)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E293B) : Colors.black.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _feedType = "orders";
                                _isSelectionMode = false;
                                _selectedItemIds.clear();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              decoration: BoxDecoration(
                                color: _feedType == "orders"
                                    ? (isDarkMode ? const Color(0xFF334155) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: _feedType == "orders"
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                        )
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  "Orders",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _feedType == "orders"
                                        ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
                                        : (isDarkMode ? Colors.white54 : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _feedType = "enquiries";
                                _isSelectionMode = false;
                                _selectedItemIds.clear();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              decoration: BoxDecoration(
                                color: _feedType == "enquiries"
                                    ? (isDarkMode ? const Color(0xFF334155) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: _feedType == "enquiries"
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                        )
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  "Enquiries",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _feedType == "enquiries"
                                        ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
                                        : (isDarkMode ? Colors.white54 : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _feedType = "sectors";
                                _isSelectionMode = false;
                                _selectedItemIds.clear();
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              decoration: BoxDecoration(
                                color: _feedType == "sectors"
                                    ? (isDarkMode ? const Color(0xFF334155) : Colors.white)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: _feedType == "sectors"
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                        )
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  "Sectors",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: _feedType == "sectors"
                                        ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
                                        : (isDarkMode ? Colors.white54 : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const OthersCategoryScreen()),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Center(
                                child: Text(
                                  "Others",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip("All", "all"),
                        SizedBox(width: 8.w),
                        _buildFilterChip("Today", "today"),
                        SizedBox(width: 8.w),
                        _buildFilterChip("Not Replied", "unreplied"),
                        SizedBox(width: 8.w),
                        _buildFilterChip("Reply Received", "received"),
                        SizedBox(width: 8.w),
                        _buildFilterChip("Sent Reply", "sent"),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                   MultiSelectCategoryDropdown(
                    categories: _currentFeedCategories,
                    selectedCategories: _feedType == "orders"
                        ? _selectedOrdersCategories
                        : (_feedType == "enquiries" ? _selectedEnquiriesCategories : _selectedSectorsCategories),
                    module: _feedType == "orders" ? "bulk_order" : _feedType == "enquiries" ? "enquiry" : "sector",
                    hint: "Filter by Categories",
                    onChanged: (selected) {
                      setState(() {
                        if (_feedType == "orders") {
                          _selectedOrdersCategories = selected;
                        } else if (_feedType == "enquiries") {
                          _selectedEnquiriesCategories = selected;
                        } else {
                          _selectedSectorsCategories = selected;
                        }
                      });
                    },
                  ),
                  SizedBox(height: 12.h),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: TextField(
                      style: GoogleFonts.outfit(
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13.sp,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search feed by name, company or product...",
                        hintStyle: GoogleFonts.outfit(
                          color: isDarkMode ? Colors.white38 : Colors.black38,
                          fontSize: 12.sp,
                        ),
                        border: InputBorder.none,
                        icon: Icon(Icons.search_rounded, size: 18.r, color: isDarkMode ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Feed list
                  _isFeedLoading
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.h),
                            child: const CircularProgressIndicator(),
                          ),
                        )
                      : Column(
                          children: [
                            _buildFeedList(isDarkMode, filtered),
                            if (_isLoadingMore)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 16.h),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _feedFilter == value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        setState(() {
          _feedFilter = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDarkMode ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedList(bool isDarkMode, List<dynamic> filtered) {
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Column(
            children: [
              Icon(Icons.feed_outlined, size: 48.r, color: isDarkMode ? Colors.white24 : Colors.black26),
              SizedBox(height: 10.h),
              Text(
                "No data available for your assigned categories.",
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final id = item["id"] is int ? item["id"] : int.tryParse(item["id"].toString()) ?? 0;
        final name = item["name"] ?? "N/A";
        final company = item["company"] ?? "N/A";
        final product = item["product"] ?? "N/A";
        final date = item["submittedAt"] ?? item["submitted_at"] ?? "";
        final isToday = _isToday(date);
        
        final msgs = _chatMessages[id] ?? [];
        String statusLabel = "No chat";
        Color statusColor = Colors.grey;
        if (msgs.isNotEmpty) {
          final last = msgs.last;
          final sender = last["sender"]?.toString().toLowerCase() ?? "";
          if (sender == "admin") {
            statusLabel = "Replied";
            statusColor = const Color(0xFF10B981);
          } else {
            statusLabel = "New Message";
            statusColor = const Color(0xFFF59E0B);
          }
        } else {
          statusLabel = "Unreplied";
          statusColor = const Color(0xFFEC4899);
        }

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            leading: _isSelectionMode
                ? Checkbox(
                    value: _selectedItemIds.contains(id),
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) {
                      _toggleItemSelection(id);
                    },
                  )
                : null,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (isToday)
                  Container(
                    margin: EdgeInsets.only(right: 6.w),
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B5BDB).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      "TODAY",
                      style: GoogleFonts.outfit(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3B5BDB),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    final phone = item["phone"] ?? item["mobile"] ?? "";
                    String moduleStr = "enquiry";
                    if (_feedType == "sectors") moduleStr = "sector";
                    if (_feedType == "bulk") moduleStr = "bulk_order";
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          referenceId: id,
                          module: moduleStr,
                          userName: name,
                          userPhone: phone,
                          userId: item["user_id"] != null ? int.tryParse(item["user_id"].toString()) : null,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 6.h),
                Text(
                  _feedType == "sectors" ? "Sector/Product: $product" : "Product: $product",
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    color: isDarkMode ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                Text(
                  _feedType == "sectors" ? "Category: $company" : "Company: $company",
                  style: GoogleFonts.outfit(
                    fontSize: 11.sp,
                    color: isDarkMode ? Colors.white38 : Colors.black45,
                  ),
                ),
                if (date.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    date,
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14.r, color: isDarkMode ? Colors.white38 : Colors.black38),
            onTap: _isSelectionMode
                ? () => _toggleItemSelection(id)
                : () => _showFeedItemDetails(item, _feedType),
            onLongPress: () {
              setState(() {
                _isSelectionMode = true;
                _selectedItemIds.add(id);
              });
            },
          ),
        );
      },
    );
  }

  void _showFeedItemDetails(dynamic item, String feedType) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final id = item["id"] is int ? item["id"] : int.tryParse(item["id"].toString()) ?? 0;
    final name = item["name"] ?? "N/A";
    final company = item["company"] ?? "N/A";
    final product = item["product"] ?? "N/A";
    final email = item["email"] ?? "N/A";
    final phone = item["phone"] ?? item["mobile"] ?? "N/A";
    final date = item["submittedAt"] ?? item["submitted_at"] ?? "N/A";
    
    final quantity = item["quantity"] ?? "N/A";
    final deliveryDate = item["deliveryDate"] ?? "N/A";
    final specialInstructions = item["specialInstructions"] ?? "N/A";
    
    final subject = item["subject"] ?? "N/A";
    final message = item["message"] ?? "N/A";

    final mrp = item["mrp"] ?? "N/A";
    final price = item["price"] ?? "N/A";
    final category = item["category"] ?? "N/A";
    final webLink = item["current_url"] ?? "N/A";

    String title = "Enquiry Details";
    String emailSubject = "Enquiry Response";
    String chatModule = "enquiry";

    if (feedType == "orders") {
      title = "Bulk Order Details";
      emailSubject = "Bulk Order Response";
      chatModule = "bulk_order";
    } else if (feedType == "sectors") {
      title = "Sector / Product Details";
      emailSubject = "Sector Response";
      chatModule = "sector";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Divider(height: 24),
              
              _buildDetailRow("Client Name", name, isDarkMode),
              _buildDetailRow(feedType == "sectors" ? "Category" : "Company", company, isDarkMode),
              _buildDetailRow(feedType == "sectors" ? "Sector / Product" : "Product / Service", product, isDarkMode),
              _buildDetailRow("Phone", phone, isDarkMode),
              _buildDetailRow("Email", email, isDarkMode),
              _buildDetailRow(feedType == "sectors" ? "Date" : "Submitted Date", date, isDarkMode),
              
              if (feedType == "orders") ...[
                _buildDetailRow("Quantity", quantity.toString(), isDarkMode),
                _buildDetailRow("Preferred Delivery", deliveryDate, isDarkMode),
                _buildDetailRow("Instructions", specialInstructions, isDarkMode),
              ] else if (feedType == "enquiries") ...[
                _buildDetailRow("Subject", subject, isDarkMode),
                _buildDetailRow("Message", message, isDarkMode),
              ] else if (feedType == "sectors") ...[
                _buildDetailRow("MRP", mrp.toString(), isDarkMode),
                _buildDetailRow("Price", price.toString(), isDarkMode),
                _buildDetailRow("Quantity", quantity.toString(), isDarkMode),
                _buildDetailRow("Category", category, isDarkMode),
                _buildDetailRow("Website Link", webLink, isDarkMode),
              ],
              
              SizedBox(height: 24.h),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.phone_rounded, size: 16),
                      label: const Text("Call"),
                      onPressed: () => _launchCall(phone),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.reply_rounded, size: 16),
                      label: const Text("Reply"),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog<bool>(
                          context: context,
                          builder: (context) => ReplyFormDialog(
                            phone: phone == "N/A" ? "" : phone,
                            fullData: item,
                            email: email == "N/A" ? "" : email,
                            name: name == "N/A" ? "" : name,
                            company: company == "N/A" ? "" : company,
                            initialSubject: product.isNotEmpty && product != "N/A" ? product : emailSubject,
                            module: chatModule,
                            referenceId: id,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat_rounded, size: 16),
                      label: const Text("Chat / Reply"),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              module: chatModule,
                              referenceId: id,
                              userName: name,
                            ),
                          ),
                        ).then((_) => _fetchFeedData());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEC4899),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white54 : const Color(0xFF475569),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleItemSelection(int id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
        if (_selectedItemIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItemIds.add(id);
      }
    });
  }

  void _selectAllItems(List<dynamic> filteredItems) {
    setState(() {
      for (final item in filteredItems) {
        final id = item["id"] is int ? item["id"] : int.tryParse(item["id"].toString()) ?? 0;
        _selectedItemIds.add(id);
      }
      _isSelectionMode = true;
    });
  }

  void _deselectAllItems() {
    setState(() {
      _selectedItemIds.clear();
    });
  }

  void _cancelSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItemIds.clear();
    });
  }

  String _formatSelectedItemsSummary() {
    final items = _feedType == "orders"
        ? _dashboardOrders
        : (_feedType == "enquiries" ? _dashboardEnquiries : _dashboardSectors);
    final selected = items.where((item) {
      final id = item["id"] is int ? item["id"] : int.tryParse(item["id"].toString()) ?? 0;
      return _selectedItemIds.contains(id);
    }).toList();

    final buffer = StringBuffer();
    if (_feedType == "orders") {
      buffer.writeln("📦 srivagroups.in - Bulk Orders:");
      for (int i = 0; i < selected.length; i++) {
        final o = selected[i];
        buffer.writeln("${i + 1}. Client: ${o['name'] ?? 'N/A'}");
        buffer.writeln("   Product: ${o['product'] ?? 'N/A'} (Qty: ${o['quantity'] ?? 'N/A'})");
        buffer.writeln("   Company: ${o['company'] ?? 'N/A'}");
        if (o['specialInstructions'] != null && o['specialInstructions'] != "N/A") {
          buffer.writeln("   Instructions: ${o['specialInstructions']}");
        }
        buffer.writeln("");
      }
    } else if (_feedType == "enquiries") {
      buffer.writeln("💬 srivagroups.in - Enquiries:");
      for (int i = 0; i < selected.length; i++) {
        final e = selected[i];
        buffer.writeln("${i + 1}. Client: ${e['name'] ?? 'N/A'}");
        buffer.writeln("   Product: ${e['product'] ?? 'N/A'}");
        buffer.writeln("   Subject: ${e['subject'] ?? 'N/A'}");
        if (e['message'] != null && e['message'] != "N/A") {
          buffer.writeln("   Message: ${e['message']}");
        }
        buffer.writeln("");
      }
    } else {
      buffer.writeln("🏢 srivagroups.in - Sectors / Products:");
      for (int i = 0; i < selected.length; i++) {
        final s = selected[i];
        buffer.writeln("${i + 1}. Title: ${s['product'] ?? 'N/A'}");
        buffer.writeln("   Category: ${s['company'] ?? 'N/A'}");
        if (s['price'] != null && s['price'] != "N/A") {
          buffer.writeln("   Price: ${s['price']}");
        }
        buffer.writeln("");
      }
    }
    return buffer.toString().trim();
  }

  void _showShareOptionsSheet() {
    final shareText = _formatSelectedItemsSummary();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Share Selected (${_selectedItemIds.length})",
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 20.h),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF25D366).withOpacity(0.12),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
                ),
                title: Text("Share via WhatsApp", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  final url = "https://wa.me/?text=${Uri.encodeComponent(shareText)}";
                  await _launchUrl(url);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.12),
                  child: const Icon(Icons.sms_rounded, color: Colors.blue),
                ),
                title: Text("Share via SMS", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  final url = "sms:?body=${Uri.encodeComponent(shareText)}";
                  await _launchUrl(url);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.12),
                  child: const Icon(Icons.email_rounded, color: Colors.red),
                ),
                title: Text("Share via Gmail / Email", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  final url = "mailto:?subject=${Uri.encodeComponent('Shared ${ _feedType == 'orders' ? 'Bulk Orders' : _feedType == 'enquiries' ? 'Enquiries' : 'Sectors' }')}&body=${Uri.encodeComponent(shareText)}";
                  await _launchUrl(url);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.12),
                  child: const Icon(Icons.forum_rounded, color: Color(0xFF6366F1)),
                ),
                title: Text("Share to Internal Chat", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _shareToInternalChat(shareText);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.12),
                  child: const Icon(Icons.share_rounded, color: Colors.orange),
                ),
                title: Text("Share via Other Apps", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  SharingIntentHandler.shareTextExternally(shareText);
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  void _shareToInternalChat(String shareText) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Share to Internal Chat",
                style: GoogleFonts.outfit(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 12.h),
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        unselectedLabelColor: isDarkMode ? Colors.white54 : Colors.black54,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        tabs: const [
                          Tab(text: "Orders"),
                          Tab(text: "Enquiries"),
                          Tab(text: "Sectors"),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildThreadSelectorList("bulk_order", _dashboardOrders, shareText),
                            _buildThreadSelectorList("enquiry", _dashboardEnquiries, shareText),
                            _buildThreadSelectorList("sector", _dashboardSectors, shareText),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThreadSelectorList(String module, List<dynamic> items, String shareText) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (items.isEmpty) {
      return Center(
        child: Text(
          "No threads available",
          style: GoogleFonts.outfit(
            fontSize: 12.sp,
            color: isDarkMode ? Colors.white38 : Colors.black38,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item["id"] is int ? item["id"] : int.tryParse(item["id"].toString()) ?? 0;
        final name = item["name"] ?? "N/A";
        final product = item["product"] ?? "N/A";
        return ListTile(
          title: Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            product,
            style: GoogleFonts.outfit(
              fontSize: 11.sp,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
          trailing: Icon(Icons.send_rounded, size: 18.r, color: Theme.of(context).colorScheme.primary),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  module: module,
                  referenceId: id,
                  userName: name,
                  initialSharedText: shareText,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("[DashboardScreen] Could not launch URL: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open application for sharing: $e")),
      );
    }
  }
}

