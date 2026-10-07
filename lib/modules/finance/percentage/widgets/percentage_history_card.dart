import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/percentage_result_model.dart';
import '../utils/percentage_formatter.dart';

class PercentageHistoryCard extends StatelessWidget {
  final List<PercentageResultModel> history;
  final ValueChanged<int> onDeleteItem;
  final VoidCallback onClearAll;
  final Function(PercentageResultModel) onSelectHistoryItem;

  const PercentageHistoryCard({
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
                
                final keys = item.inputValues.keys.toList();
                final val1 = keys.isNotEmpty ? item.inputValues[keys[0]]! : 0.0;
                final val2 = keys.length > 1 ? item.inputValues[keys[1]]! : 0.0;

                final val1Str = _formatDisplayValue(item.calculationType, keys.isNotEmpty ? keys[0] : '', val1);
                final val2Str = _formatDisplayValue(item.calculationType, keys.length > 1 ? keys[1] : '', val2);
                
                final outVal = _formatPercentageDisplay(item.calculationType, item.percentage);

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
                                        item.calculationType,
                                        style: GoogleFonts.outfit(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      PercentageFormatter.formatDate(item.createdAt).split(',')[1].trim(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 9.sp,
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
                                      TextSpan(text: '${keys.isNotEmpty ? keys[0] : "Val 1"}: '),
                                      TextSpan(
                                        text: val1Str,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      TextSpan(text: ' | ${keys.length > 1 ? keys[1] : "Val 2"}: '),
                                      TextSpan(
                                        text: val2Str,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _getPercentageLabel(item.calculationType),
                                style: GoogleFonts.outfit(
                                  fontSize: 9.sp,
                                  color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                outVal,
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

  String _formatDisplayValue(String type, String key, double val) {
    final low = key.toLowerCase();
    if (low.contains('price') || low.contains('amount') || low.contains('cost') || low.contains('sale') || low.contains('profit') || low.contains('loss') || low.contains('discount') || low.contains('markup') || low.contains('commission')) {
      return PercentageFormatter.formatIndianCurrency(val);
    }
    final isInt = val == val.toInt();
    return isInt ? val.toInt().toString() : val.toStringAsFixed(2);
  }

  String _formatPercentageDisplay(String type, double val) {
    if (type == 'Discount Calculator' || type == 'Markup Calculator' || type == 'Commission Calculator') {
      return PercentageFormatter.formatIndianCurrency(val);
    }
    return PercentageFormatter.formatPercentage(val);
  }

  String _getPercentageLabel(String type) {
    switch (type) {
      case 'Percentage of Number':
        return 'Rate';
      case 'What Percentage?':
        return 'Percentage';
      case 'Percentage Increase':
        return 'Increase %';
      case 'Percentage Decrease':
        return 'Decrease %';
      case 'Percentage Difference':
        return 'Diff %';
      case 'Profit Percentage':
        return 'Profit %';
      case 'Loss Percentage':
        return 'Loss %';
      case 'Discount Calculator':
        return 'Savings';
      case 'Markup Calculator':
        return 'Added Markup';
      case 'Margin Calculator':
        return 'Margin %';
      case 'Percentage Change':
        return 'Change %';
      case 'Commission Calculator':
        return 'Commission';
      default:
        return 'Rate';
    }
  }
}
