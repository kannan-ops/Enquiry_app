import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enquiry_app/chartfile/chat_screen.dart';

class NewChatContactsScreen extends StatefulWidget {
  final List<dynamic> orders;
  final List<dynamic> enquiries;
  final List<dynamic> sectors;

  const NewChatContactsScreen({
    super.key,
    required this.orders,
    required this.enquiries,
    required this.sectors,
  });

  @override
  State<NewChatContactsScreen> createState() => _NewChatContactsScreenState();
}

class _NewChatContactsScreenState extends State<NewChatContactsScreen> {
  String _searchQuery = "";
  String _activeTab = "all";
  late List<Map<String, dynamic>> _allContacts;

  @override
  void initState() {
    super.initState();
    _allContacts = _buildAllContacts();
  }

  List<Map<String, dynamic>> _buildAllContacts() {
    final List<Map<String, dynamic>> contacts = [];

    void addContacts(List<dynamic> items, String module, String moduleLabel) {
      for (var item in items) {
        if (item is! Map) continue;
        final idVal = item["id"];
        final id = idVal is int ? idVal : int.tryParse(idVal.toString()) ?? 0;
        if (id == 0) continue;

        contacts.add({
          "id": id,
          "name": item["name"] ?? item["client_name"] ?? item["title"] ?? item["product"] ?? item["company"] ?? "Client",
          "phone": item["phone"] ?? item["mobile"] ?? item["contact_number"] ?? item["phone_number"] ?? "",
          "module": module,
          "moduleLabel": moduleLabel,
          "timestamp": item["created_at"] ?? item["timestamp"] ?? "",
        });
      }
    }

    addContacts(widget.orders, "bulk_order", "Bulk Order");
    addContacts(widget.enquiries, "enquiry", "Enquiry");
    addContacts(widget.sectors, "sector", "Sector Product");

    // Sort alphabetically by name
    contacts.sort((a, b) {
      final nameA = a["name"].toString().toLowerCase();
      final nameB = b["name"].toString().toLowerCase();
      return nameA.compareTo(nameB);
    });

    return contacts;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final filteredContacts = _allContacts.where((contact) {
      final name = contact["name"].toString().toLowerCase();
      final q = _searchQuery.toLowerCase().trim();
      
      final matchesSearch = name.contains(q);
      if (!matchesSearch) return false;

      if (_activeTab != "all") {
        return contact["module"] == _activeTab;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Select Contact",
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
                  hintText: "Search contacts...",
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildTabButton("All", "all"),
                    SizedBox(width: 8.w),
                    _buildTabButton("Bulk", "bulk_order"),
                    SizedBox(width: 8.w),
                    _buildTabButton("Enquiry", "enquiry"),
                    SizedBox(width: 8.w),
                    _buildTabButton("Sector", "sector"),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            Padding(
              padding: EdgeInsets.only(left: 20.w, bottom: 8.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Contacts on System (${filteredContacts.length})",
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
            ),

            // Contacts List
            Expanded(
              child: filteredContacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off_rounded,
                            size: 64.r,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            "No contacts found",
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        final moduleLabel = contact["moduleLabel"].toString();
                        
                        Color moduleColor = const Color(0xFF3B5BDB);
                        if (contact["module"] == "enquiry") {
                          moduleColor = const Color(0xFF10B981);
                        } else if (contact["module"] == "sector") {
                          moduleColor = const Color(0xFFF59E0B);
                        }

                        return Card(
                          margin: EdgeInsets.only(bottom: 12.h),
                          elevation: 1,
                          shadowColor: Colors.black.withOpacity(0.02),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                            side: BorderSide(color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.03)),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.r),
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    module: contact["module"],
                                    referenceId: contact["id"],
                                    userName: contact["name"],
                                    userPhone: contact["phone"],
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
                                      contact["name"].toString().substring(0, 1).toUpperCase(),
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
                                        Text(
                                          contact["name"],
                                          style: GoogleFonts.outfit(
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4.h),
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
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chat_bubble_rounded,
                                    color: moduleColor.withOpacity(0.5),
                                    size: 20.r,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String value) {
    final isSelected = _activeTab == value;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? const Color(0xFF6366F1) : const Color(0xFF6366F1))
              : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20.r),
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
    );
  }
}
