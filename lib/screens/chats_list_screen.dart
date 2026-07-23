import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enquiry_app/chartfile/chat_screen.dart';
import 'package:enquiry_app/screens/new_chat_contacts_screen.dart';
import 'package:enquiry_app/utils/api_debug_logger.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = "";
  String _activeTab = "all"; // "all" or "pending"

  // Data State
  List<Map<String, dynamic>> _activeChats = [];
  List<dynamic> _allOrders = [];
  List<dynamic> _allEnquiries = [];
  List<dynamic> _allSectors = [];

  // Pagination State
  int _page = 1;
  final int _limit = 20;
  bool _isLoading = false;
  bool _hasMoreBulk = true;
  bool _hasMoreEnq = true;
  bool _hasMoreSec = true;
  
  // Error State
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNextPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  List<dynamic> _extractList(dynamic json) {
    if (json == null) return [];
    if (json is List) return json;
    if (json is Map) {
      if (json.containsKey('data')) {
        final d = json['data'];
        if (d is List) return d;
        if (d is Map) {
          if (d.containsKey('data')) {
            final dd = d['data'];
            if (dd is List) return dd;
          }
          if (d.containsKey('messages')) {
            final dm = d['messages'];
            if (dm is List) return dm;
          }
        }
      }
      if (json.containsKey('messages')) {
        final m = json['messages'];
        if (m is List) return m;
      }
      for (var val in json.values) {
        if (val is List) {
          return val;
        }
        if (val is Map) {
          final sub = _extractList(val);
          if (sub.isNotEmpty) return sub;
        }
      }
    }
    return [];
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || (!_hasMoreBulk && !_hasMoreEnq && !_hasMoreSec)) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    int fetchAttempts = 0;
    int initialChatCount = _activeChats.length;

    try {
      while (fetchAttempts < 3 && (_hasMoreBulk || _hasMoreEnq || _hasMoreSec) && _activeChats.length == initialChatCount) {
        fetchAttempts++;

        Future<void> checkChats(List<dynamic> items, String module, String moduleLabel) async {
          final messageFutures = <Future<void>>[];
          for (var item in items) {
            final id = item["id"] is int ? item["id"] : int.tryParse(item["id"].toString()) ?? 0;
            if (id == 0) continue;

            messageFutures.add(() async {
              try {
                final url = "https://bulk.srivagroups.in/api/messages/$module/$id";
                final res = await ApiDebugLogger.httpClient.get(Uri.parse(url));
                if (res.statusCode == 200) {
                  final decoded = jsonDecode(res.body);
                  List<dynamic> msgs = _extractList(decoded);

                  if (msgs.isNotEmpty) {
                    // Only show chats where the logged-in user has sent at least one message
                    final hasUserMessage = msgs.any(
                      (m) => m["sender"]?.toString().toLowerCase() == "user",
                    );
                    if (!hasUserMessage) return;

                    final lastMsg = msgs.last;
                    final lastMsgText = lastMsg["message"]?.toString() ?? "";
                    final lastMsgSender = lastMsg["sender"]?.toString() ?? "";
                    final timestamp = lastMsg["timestamp"] ?? lastMsg["created_at"];

                    if (mounted) {
                      setState(() {
                        _activeChats.add({
                          "id": id,
                          "name": item["name"] ?? item["client_name"] ?? item["title"] ?? item["product"] ?? item["company"] ?? "Client",
                          "phone": item["phone"] ?? item["mobile"] ?? item["contact_number"] ?? item["phone_number"] ?? "",
                          "module": module,
                          "moduleLabel": moduleLabel,
                          "lastMessage": lastMsgText,
                          "lastSender": lastMsgSender,
                          "timestamp": timestamp,
                          // Pending reply = last message is from user (admin hasn't replied yet)
                          "isUnread": lastMsgSender.toLowerCase() == "user",
                        });

                        // Sort immediately to show in correct order
                        _activeChats.sort((a, b) {
                          final timeA = a["timestamp"]?.toString() ?? "";
                          final timeB = b["timestamp"]?.toString() ?? "";
                          if (timeA.isNotEmpty && timeB.isNotEmpty) {
                            return timeB.compareTo(timeA);
                          }
                          return b["id"].compareTo(a["id"]);
                        });
                      });
                    }
                  }

                } else {
                   debugPrint("Failed to load messages for $module $id: ${res.statusCode}");
                }
              } catch (e) {
                 debugPrint("Exception loading messages for $module $id: $e");
              }
            }());
          }
          await Future.wait(messageFutures);
        }

        Future<void> fetchAndProcessModule(String endpoint, String module, String moduleLabel, bool hasMore, List<dynamic> targetList, Function(bool) setHasMore) async {
          if (!hasMore) return;
          try {
            final url = "https://bulk.srivagroups.in/api/$endpoint?limit=$_limit&page=$_page";
            final res = await ApiDebugLogger.httpClient.get(Uri.parse(url));
            if (res.statusCode == 200) {
              final decoded = jsonDecode(res.body);
              final items = _extractList(decoded);
              if (items.length < _limit) setHasMore(false);
              targetList.addAll(items);
              await checkChats(items, module, moduleLabel);
            }
          } catch (e) {
            debugPrint("Network Exception for $endpoint: $e");
          }
        }

        await Future.wait([
          fetchAndProcessModule("bulk-orders", "bulk_order", "Bulk Order", _hasMoreBulk, _allOrders, (v) => _hasMoreBulk = v),
          fetchAndProcessModule("enquiries", "enquiry", "Enquiry", _hasMoreEnq, _allEnquiries, (v) => _hasMoreEnq = v),
          fetchAndProcessModule("product", "product", "Sector Product", _hasMoreSec, _allSectors, (v) => _hasMoreSec = v),
        ]);

        if (mounted) {
          setState(() {
            _page++;
          });
        }
      }
    } catch (e, stacktrace) {
      debugPrint("Fatal Error in ChatsListScreen pagination: $e\n$stacktrace");
      if (mounted && _activeChats.isEmpty) {
        setState(() {
          _errorMessage = "Failed to load chats. Please check your connection and try again.\nError: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(dynamic rawTime) {
    if (rawTime == null) return "";
    try {
      final parsed = DateTime.parse(rawTime.toString()).toLocal();
      final now = DateTime.now();
      final difference = now.difference(parsed);

      if (difference.inDays == 0) {
        int hour = parsed.hour;
        final String period = hour >= 12 ? "PM" : "AM";
        hour = hour % 12;
        if (hour == 0) hour = 12;
        final String minuteStr = parsed.minute.toString().padLeft(2, '0');
        return "$hour:$minuteStr $period";
      } else if (difference.inDays == 1) {
        return "Yesterday";
      } else {
        return "${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}";
      }
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Filter by search query and active tab
    final filteredChats = _activeChats.where((chat) {
      final name = chat["name"].toString().toLowerCase();
      final msg = chat["lastMessage"].toString().toLowerCase();
      final q = _searchQuery.toLowerCase().trim();
      
      final matchesSearch = name.contains(q) || msg.contains(q);
      if (!matchesSearch) return false;

      if (_activeTab == "pending") {
        return chat["isUnread"] == true;
      }
      return true;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewChatContactsScreen(
                orders: _allOrders,
                enquiries: _allEnquiries,
                sectors: _allSectors,
              ),
            ),
          ).then((_) {
            if (mounted) setState(() {});
          });
        },
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.chat_rounded, color: Colors.white),
      ),
      appBar: AppBar(
        title: Text(
          "Active Chats",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF6366F1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [const Color(0xFF0B0F19), const Color(0xFF111827)]
                : [const Color(0xFFF8FAFC), const Color(0xFFEFF6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: EdgeInsets.all(16.r),
              child: TextField(
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search client or message...",
                  hintStyle: TextStyle(color: isDarkMode ? Colors.white60 : Colors.black45),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h),
                ),
              ),
            ),

            // Tabs / Filters
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  _buildTabButton("All Chats (${_activeChats.length})", "all"),
                  SizedBox(width: 12.w),
                  _buildTabButton(
                    "Pending Reply (${_activeChats.where((c) => c["isUnread"] == true).length})",
                    "pending",
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Main Content Area
            Expanded(
              child: _buildMainContent(filteredChats, isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(List<Map<String, dynamic>> filteredChats, bool isDarkMode) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 64.r, color: Colors.redAccent),
              SizedBox(height: 16.h),
              Text(
                "Something went wrong",
                style: GoogleFonts.outfit(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _loadNextPage();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredChats.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64.r,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              "No active chats found",
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: filteredChats.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == filteredChats.length) {
           return Padding(
             padding: EdgeInsets.symmetric(vertical: 24.h),
             child: const Center(
               child: CircularProgressIndicator(
                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
               ),
             ),
           );
        }

        final chat = filteredChats[index];
        final isUnread = chat["isUnread"] == true;
        final moduleLabel = chat["moduleLabel"].toString();
        
        Color moduleColor = const Color(0xFF3B5BDB);
        if (chat["module"] == "enquiry") {
          moduleColor = const Color(0xFF10B981);
        } else if (chat["module"] == "sector") {
          moduleColor = const Color(0xFFF59E0B);
        }

        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: isUnread ? 4 : 1,
          shadowColor: isUnread ? moduleColor.withOpacity(0.15) : Colors.black.withOpacity(0.02),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
            side: isUnread
                ? BorderSide(color: moduleColor.withOpacity(0.4), width: 1.5)
                : BorderSide(color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.03)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    module: chat["module"],
                    referenceId: chat["id"],
                    userName: chat["name"],
                    userPhone: chat["phone"],
                  ),
                ),
              );
            },
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  // User Avatar/Badge
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: moduleColor.withOpacity(0.1),
                    child: Text(
                      chat["name"].toString().substring(0, 1).toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: moduleColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),

                  // Chat Info details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                chat["name"],
                                style: GoogleFonts.outfit(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(chat["timestamp"]),
                              style: GoogleFonts.outfit(
                                fontSize: 11.sp,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: moduleColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                moduleLabel,
                                style: GoogleFonts.outfit(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  color: moduleColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                chat["lastMessage"],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.sp,
                                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                                  color: isDarkMode
                                      ? (isUnread ? Colors.white : Colors.white60)
                                      : (isUnread ? Colors.black : Colors.black54),
                                ),
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8.r,
                                height: 8.r,
                                decoration: const BoxDecoration(
                                  color: Colors.orangeAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String label, String value) {
    final isSelected = _activeTab == value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = value;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode ? const Color(0xFF6366F1) : const Color(0xFF6366F1))
                : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? Colors.transparent : (isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05)),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }
}
