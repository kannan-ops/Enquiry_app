import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:enquiry_app/utils/sharing_intent_handler.dart';
import 'package:enquiry_app/chartfile/chat_screen.dart';
import 'package:enquiry_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MultiSelectCategoryDropdown extends StatefulWidget {
  final List<String> categories;
  final List<String> selectedCategories;
  final Function(List<String>) onChanged;
  final String module; // "bulk_order", "enquiry", or "sector"
  final String hint;

  const MultiSelectCategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategories,
    required this.onChanged,
    required this.module,
    this.hint = "Select Categories",
  });

  @override
  State<MultiSelectCategoryDropdown> createState() => _MultiSelectCategoryDropdownState();
}

class _MultiSelectCategoryDropdownState extends State<MultiSelectCategoryDropdown> {
  String _searchQuery = "";

  void _showCategorySelectionBottomSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Filter categories based on search query
            final filtered = widget.categories.where((cat) {
              final displayCat = cat.isEmpty ? "No Category" : cat;
              return displayCat.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 16.h),
              child: Column(
                children: [
                  // Pull handler
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
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.hint,
                        style: GoogleFonts.outfit(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800,
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "${widget.selectedCategories.length} Selected",
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  // Sticky Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E293B) : Colors.black.withOpacity(0.03),
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
                        setModalState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search categories...",
                        hintStyle: GoogleFonts.outfit(
                          color: isDarkMode ? Colors.white38 : Colors.black38,
                          fontSize: 12.sp,
                        ),
                        border: InputBorder.none,
                        icon: Icon(Icons.search_rounded, size: 18.r, color: isDarkMode ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  // Sticky Controls Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.select_all_rounded, size: 16),
                        label: const Text("Select All"),
                        onPressed: () {
                          final newSelection = List<String>.from(widget.selectedCategories);
                          for (final cat in filtered) {
                            if (!newSelection.contains(cat)) {
                              newSelection.add(cat);
                            }
                          }
                          widget.onChanged(newSelection);
                          setModalState(() {});
                          setState(() {});
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.deselect_rounded, size: 16),
                        label: const Text("Deselect All"),
                        style: TextButton.styleFrom(foregroundColor: Colors.orange),
                        onPressed: () {
                          final newSelection = List<String>.from(widget.selectedCategories);
                          for (final cat in filtered) {
                            newSelection.remove(cat);
                          }
                          widget.onChanged(newSelection);
                          setModalState(() {});
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  // List of checkboxes
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final cat = filtered[index];
                        final displayCat = cat.isEmpty ? "No Category" : cat;
                        final isChecked = widget.selectedCategories.contains(cat);

                        return CheckboxListTile(
                          value: isChecked,
                          title: Text(
                            displayCat,
                            style: GoogleFonts.outfit(
                              fontSize: 13.sp,
                              color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (checked) {
                            final newSelection = List<String>.from(widget.selectedCategories);
                            if (checked == true) {
                              newSelection.add(cat);
                            } else {
                              newSelection.remove(cat);
                            }
                            widget.onChanged(newSelection);
                            setModalState(() {});
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _searchQuery = "";
      });
    });
  }

  void _showAllSelectedDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            "Selected Categories",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.selectedCategories.length,
              itemBuilder: (context, index) {
                final cat = widget.selectedCategories[index];
                final displayCat = cat.isEmpty ? "No Category" : cat;
                return ListTile(
                  title: Text(displayCat, style: GoogleFonts.outfit(fontSize: 13.sp)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.red),
                    onPressed: () {
                      final newSelection = List<String>.from(widget.selectedCategories);
                      newSelection.remove(cat);
                      widget.onChanged(newSelection);
                      Navigator.pop(context);
                      setState(() {});
                      if (newSelection.isNotEmpty) {
                        _showAllSelectedDialog();
                      }
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _shareCategories(BuildContext context) {
    if (widget.selectedCategories.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln("Selected Categories\n");
    for (final cat in widget.selectedCategories) {
      buffer.writeln("• ${cat.isEmpty ? 'No Category' : cat}");
    }
    final shareText = buffer.toString().trim();
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
                "Share Selected Categories",
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
                  final url = "mailto:?subject=${Uri.encodeComponent('Selected Categories')}&body=${Uri.encodeComponent(shareText)}";
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
                  backgroundColor: Colors.teal.withOpacity(0.12),
                  child: const Icon(Icons.copy_all_rounded, color: Colors.teal),
                ),
                title: Text("Copy to Clipboard", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: shareText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Categories copied to clipboard!")),
                  );
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

  Future<void> _shareToInternalChat(String shareText) async {
    final prefs = await SharedPreferences.getInstance();
    final String lastModule = prefs.getString('last_chat_module') ?? 'enquiry';
    final int refId = prefs.getInt('last_chat_reference_id') ?? 1;
    final String userName = prefs.getString('last_chat_user_name') ?? 'Client';

    NavigationService.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          module: lastModule,
          referenceId: refId,
          userName: userName,
          initialSharedText: shareText,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("[MultiSelectCategoryDropdown] Could not launch URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _showCategorySelectionBottomSheet,
              child: Row(
                children: [
                  Icon(Icons.category_rounded, size: 18.r, color: Theme.of(context).colorScheme.primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: widget.selectedCategories.isEmpty
                        ? Text(
                            widget.hint,
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              color: isDarkMode ? Colors.white38 : Colors.black38,
                            ),
                          )
                        : Wrap(
                            spacing: 6.w,
                            runSpacing: 4.h,
                            children: [
                              ...widget.selectedCategories.take(2).map((cat) {
                                final displayCat = cat.isEmpty ? "No Category" : cat;
                                return Chip(
                                  label: Text(
                                    displayCat,
                                    style: GoogleFonts.outfit(fontSize: 10.sp, color: Colors.white),
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  onDeleted: () {
                                    final newSelection = List<String>.from(widget.selectedCategories);
                                    newSelection.remove(cat);
                                    widget.onChanged(newSelection);
                                    setState(() {});
                                  },
                                  deleteIcon: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }),
                              if (widget.selectedCategories.length > 2)
                                GestureDetector(
                                  onTap: _showAllSelectedDialog,
                                  child: Chip(
                                    label: Text(
                                      "Selected (${widget.selectedCategories.length})",
                                      style: GoogleFonts.outfit(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.grey[700],
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.selectedCategories.isNotEmpty) ...[
            IconButton(
              icon: Icon(Icons.share_rounded, size: 16.r, color: Colors.orange),
              onPressed: () => _shareCategories(context),
              tooltip: "Share selected categories",
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            SizedBox(width: 8.w),
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, size: 18.r, color: Colors.red),
              onPressed: () {
                widget.onChanged([]);
                setState(() {});
              },
              tooltip: "Deselect All",
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            SizedBox(width: 4.w),
          ],
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18.r,
            color: isDarkMode ? Colors.white54 : Colors.black54,
          ),
        ],
      ),
    );
  }
}
