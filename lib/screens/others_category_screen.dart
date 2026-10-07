import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enquiry_app/utils/api_debug_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:enquiry_app/chartfile/chat_screen.dart';
import 'package:enquiry_app/widgets/reply_form_dialog.dart';
import 'package:enquiry_app/widgets/multi_select_category_dropdown.dart';

class OthersCategoryScreen extends ConsumerStatefulWidget {
  const OthersCategoryScreen({super.key});

  @override
  ConsumerState<OthersCategoryScreen> createState() => _OthersCategoryScreenState();
}

class _OthersCategoryScreenState extends ConsumerState<OthersCategoryScreen> {
  List<dynamic> _orders = [];
  List<dynamic> _enquiries = [];
  List<dynamic> _sectors = [];
  final Map<int, List<dynamic>> _chatMessages = {};
  bool _isLoading = true;
  String _activeTab = "orders"; // "orders", "enquiries", "sectors"
  List<String> _selectedCategories = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        ApiDebugLogger.httpClient.get(
          Uri.parse("https://bulk.srivagroups.in/api/bulk-orders?limit=150"),
        ).timeout(const Duration(seconds: 8)),
        ApiDebugLogger.httpClient.get(
          Uri.parse("https://bulk.srivagroups.in/api/enquiries?limit=150"),
        ).timeout(const Duration(seconds: 8)),
        ApiDebugLogger.httpClient.get(
          Uri.parse("https://bulk.srivagroups.in/api/product?limit=150"),
        ).timeout(const Duration(seconds: 8)),
      ]);

      final resBulk = futures[0];
      final resEnq = futures[1];
      final resSec = futures[2];

      if (resBulk.statusCode == 200) {
        final decoded = jsonDecode(resBulk.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }
        _orders = list.map((x) {
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
        _orders.sort((a, b) {
          final idA = a["id"] is int ? a["id"] : int.tryParse(a["id"].toString()) ?? 0;
          final idB = b["id"] is int ? b["id"] : int.tryParse(b["id"].toString()) ?? 0;
          return idB.compareTo(idA);
        });
      }

      if (resEnq.statusCode == 200) {
        final decoded = jsonDecode(resEnq.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }
        _enquiries = list.map((x) {
          if (x is Map) {
            final item = Map<String, dynamic>.from(x);
            item['company'] ??= item['company_name'];
            item['product'] ??= item['product_name'];
            item['submittedAt'] ??= item['submitted_at'];
            return item;
          }
          return x;
        }).toList();
        _enquiries.sort((a, b) {
          final idA = a["id"] is int ? a["id"] : int.tryParse(a["id"].toString()) ?? 0;
          final idB = b["id"] is int ? b["id"] : int.tryParse(b["id"].toString()) ?? 0;
          return idB.compareTo(idA);
        });
      }

      if (resSec.statusCode == 200) {
        final decoded = jsonDecode(resSec.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded['data'] is List) {
          list = decoded['data'];
        }
        _sectors = list.map((x) {
          if (x is Map) {
            final item = Map<String, dynamic>.from(x);
            item['submittedAt'] ??= item['date'] ?? item['created_at'];
            item['product'] ??= item['title'] ?? item['name'];
            item['company'] ??= item['category'] ?? item['website_name'];
            return item;
          }
          return x;
        }).toList();
        _sectors.sort((a, b) {
          final idA = a["id"] is int ? a["id"] : int.tryParse(a["id"].toString()) ?? 0;
          final idB = b["id"] is int ? b["id"] : int.tryParse(b["id"].toString()) ?? 0;
          return idB.compareTo(idA);
        });
      }

      _fetchChatStatuses();
    } catch (e) {
      print("Error loading data in Others screen: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchChatStatuses() async {
    final List<dynamic> allItems = [..._orders, ..._enquiries, ..._sectors];
    final chunkSize = 10;
    for (var i = 0; i < allItems.length; i += chunkSize) {
      if (!mounted) return;
      final chunk = allItems.sublist(
        i,
        i + chunkSize > allItems.length ? allItems.length : i + chunkSize,
      );

      await Future.wait(chunk.map   ((item) async {
        if (item is! Map) return;
        final id = item["id"] is int ? item["id"] : int.tryParse(item["id"].toString()) ?? 0;
        if (id == 0) return;

        try {
          final isOrder = _orders.any((o) => o["id"] == id);
          final isEnq = _enquiries.any((e) => e["id"] == id);
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

  List<String> get _categories {
    final items = _activeTab == "orders"
        ? _orders
        : (_activeTab == "enquiries" ? _enquiries : _sectors);
    final cats = items
        .map((x) => _getCategoryFromItem(x))
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  void _changeTab(String tab) {
    setState(() {
      _activeTab = tab;
      _selectedCategories.clear();
    });
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
                        ).then((_) => _loadData());
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

  Widget _buildTabButton(String label, String value, bool isDarkMode) {
    final isSelected = _activeTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _changeTab(value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode ? const Color(0xFF334155) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: isSelected
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
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
                    : (isDarkMode ? Colors.white54 : Colors.black54),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final items = _activeTab == "orders"
        ? _orders
        : (_activeTab == "enquiries" ? _enquiries : _sectors);

    final filtered = items.where((item) {
      if (item is! Map) return false;

      // Category filter
      if (_selectedCategories.isNotEmpty) {
        final cat = _getCategoryFromItem(item);
        if (!_selectedCategories.contains(cat)) {
          return false;
        }
      }

      // Search query filter
      final name = (item["name"] ?? "").toString().toLowerCase();
      final company = (item["company"] ?? "").toString().toLowerCase();
      final product = (item["product"] ?? "").toString().toLowerCase();
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        if (!name.contains(q) && !company.contains(q) && !product.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF6366F1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "Category Filter",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          )
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tab controller for Bulk, Enquiry, Sector
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1E293B) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Row(
                          children: [
                            _buildTabButton("Bulk", "orders", isDarkMode),
                            _buildTabButton("Enquiry", "enquiries", isDarkMode),
                            _buildTabButton("Sector", "sectors", isDarkMode),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),

                      MultiSelectCategoryDropdown(
                        categories: _categories,
                        selectedCategories: _selectedCategories,
                        module: _activeTab == "orders" ? "bulk_order" : _activeTab == "enquiries" ? "enquiry" : "sector",
                        hint: "Filter by Categories",
                        onChanged: (selected) {
                          setState(() {
                            _selectedCategories = selected;
                          });
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Search bar
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
                            hintText: "Search categories by client name, company...",
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

                      // Dynamic filtered list
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.category_outlined,
                                      size: 48.r,
                                      color: isDarkMode ? Colors.white24 : Colors.black26,
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      "No items found for this category",
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.sp,
                                        color: isDarkMode ? Colors.white38 : Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
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
                                              if (_activeTab == "sectors") moduleStr = "sector";
                                              if (_activeTab == "bulk") moduleStr = "bulk_order";
                                              
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
                                            _activeTab == "sectors" ? "Sector/Product: $product" : "Product: $product",
                                            style: GoogleFonts.outfit(
                                              fontSize: 12.sp,
                                              color: isDarkMode ? Colors.white70 : const Color(0xFF475569),
                                            ),
                                          ),
                                          Text(
                                            _activeTab == "sectors" ? "Category: $company" : "Company: $company",
                                            style: GoogleFonts.outfit(
                                              fontSize: 11.sp,
                                              color: isDarkMode ? Colors.white38 : Colors.black45,
                                            ),
                                          ),
                                          if (_getCategoryFromItem(item).isNotEmpty && _activeTab != "sectors") ...[
                                            Text(
                                              "Category: ${_getCategoryFromItem(item)}",
                                              style: GoogleFonts.outfit(
                                                fontSize: 11.sp,
                                                color: isDarkMode ? Colors.white38 : Colors.black45,
                                              ),
                                            ),
                                          ],
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
                                      onTap: () => _showFeedItemDetails(item, _activeTab),
                                    ),
                                  );
                                },
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
