import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/gst_result_model.dart';
import '../utils/gst_formatter.dart';

class GstHistoryCard extends StatelessWidget {
  final List<GstResultModel> history;
  final ValueChanged<int> onDeleteItem;
  final VoidCallback onClearAll;
  final Function(GstResultModel) onSelectHistoryItem;

  const GstHistoryCard({
    super.key,
    required this.history,
    required this.onDeleteItem,
    required this.onClearAll,
    required this.onSelectHistoryItem,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E);
    
    if (history.isEmpty) {
      return Card(
        elevation: isDarkMode ? 0 : 1,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36.h, horizontal: 20.w),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  size: 48.r,
                  color: isDarkMode ? Colors.white30 : Colors.black26,
                ),
                SizedBox(height: 12.h),
                Text(
                  'No calculations in this session',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white38 : Colors.black45,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Your calculations will appear here.',
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    color: isDarkMode ? Colors.white24 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: isDarkMode ? 0 : 2,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 20.r,
                      color: primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Session History',
                      style: GoogleFonts.outfit(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: onClearAll,
                  icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                  label: Text(
                    'Clear All',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            
            // List of History Items
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final originalStr = GstFormatter.formatIndianCurrency(item.originalAmount);
                final finalStr = GstFormatter.formatIndianCurrency(item.finalAmount);
                final rateStr = '${item.gstPercentage}%';

                return Dismissible(
                  key: ValueKey(item.createdAt.millisecondsSinceEpoch + index),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) => onDeleteItem(index),
                  background: Container(
                    margin: EdgeInsets.symmetric(vertical: 6.h),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => onSelectHistoryItem(item),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 6.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side: Type & Inputs
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        child: Text(
                                          item.calculationType,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      GstFormatter.formatDate(item.createdAt).split(',')[1].trim(), // just show time
                                      style: GoogleFonts.outfit(
                                        fontSize: 10.sp,
                                        color: isDarkMode ? Colors.white38 : Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.sp,
                                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    ),
                                    children: [
                                      const TextSpan(text: 'Input: '),
                                      TextSpan(
                                        text: item.calculationType == 'Inclusive' ? finalStr : originalStr,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      TextSpan(text: ' @ $rateStr'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Right side: Output Amount
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Final Amount',
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp,
                                  color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                finalStr,
                                style: GoogleFonts.firaCode(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
