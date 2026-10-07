import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tax_result_model.dart';
import '../utils/tax_formatter.dart';
import '../constants/tax_constants.dart';

class TaxHistoryCard extends StatelessWidget {
  final List<TaxResultModel> history;
  final ValueChanged<int> onDeleteItem;
  final VoidCallback onClearAll;
  final Function(TaxResultModel) onSelectHistoryItem;

  const TaxHistoryCard({
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

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                
                final String timeStr = TaxFormatter.formatDate(item.createdAt).split(',')[1].trim();
                final String inputDesc = 'Base: ${TaxFormatter.formatIndianCurrency(item.originalAmount)} @ ${TaxFormatter.formatPercentage(item.taxPercentage)}';

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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Text(
                                        TaxConstants.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.outfit(
                                        fontSize: 9.sp,
                                        color: isDarkMode ? Colors.white38 : Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  inputDesc,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.sp,
                                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Tax Amount',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.sp,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                TaxFormatter.formatIndianCurrency(item.taxAmount),
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
