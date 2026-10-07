import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/gst_result_model.dart';
import '../utils/gst_formatter.dart';
import 'gst_formula_sheet.dart';
import 'gst_print_preview_dialog.dart';

class GstResultCard extends StatefulWidget {
  final GstResultModel result;

  const GstResultCard({
    super.key,
    required this.result,
  });

  @override
  State<GstResultCard> createState() => _GstResultCardState();
}

class _GstResultCardState extends State<GstResultCard> with SingleTickerProviderStateMixin {
  bool _showSteps = false;

  String _generateShareText() {
    final res = widget.result;
    final buffer = StringBuffer();
    buffer.writeln('--- GST Calculation Details ---');
    buffer.writeln('Type: ${res.calculationType}');
    buffer.writeln('Original Amount: ${GstFormatter.formatIndianCurrency(res.originalAmount)}');
    buffer.writeln('GST Percentage: ${res.gstPercentage}%');
    buffer.writeln('GST Amount: ${GstFormatter.formatIndianCurrency(res.gstAmount)}');
    if (res.cgstAmount > 0) {
      buffer.writeln('CGST Amount: ${GstFormatter.formatIndianCurrency(res.cgstAmount)}');
      buffer.writeln('SGST Amount: ${GstFormatter.formatIndianCurrency(res.sgstAmount)}');
    }
    if (res.igstAmount > 0) {
      buffer.writeln('IGST Amount: ${GstFormatter.formatIndianCurrency(res.igstAmount)}');
    }
    buffer.writeln('Final Amount: ${GstFormatter.formatIndianCurrency(res.finalAmount)}');
    buffer.writeln('Generated via CircuitPoint App');
    return buffer.toString();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generateShareText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GST calculation details copied!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPrintPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GstPrintPreviewDialog(result: widget.result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final res = widget.result;

    final primaryColor = isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E);
    
    return Card(
      elevation: isDarkMode ? 0 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(
          color: isDarkMode ? const Color(0xFF334155).withOpacity(0.3) : Colors.black.withOpacity(0.04),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Title & Type Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calculation Result',
                  style: GoogleFonts.outfit(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    res.calculationType,
                    style: GoogleFonts.outfit(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Main Display Item Grid/List
            _buildResultRow('Original Amount', GstFormatter.formatIndianCurrency(res.originalAmount), isDarkMode),
            _buildResultRow('GST Percentage', '${res.gstPercentage}%', isDarkMode),
            _buildResultRow('GST Amount', GstFormatter.formatIndianCurrency(res.gstAmount), isDarkMode, highlightColor: primaryColor),
            
            // Conditional cgst / sgst rows
            if (res.calculationType == 'CGST + SGST' || res.cgstAmount > 0) ...[
              _buildResultRow('CGST (Central GST - 50%)', GstFormatter.formatIndianCurrency(res.cgstAmount), isDarkMode, isSubItem: true),
              _buildResultRow('SGST (State GST - 50%)', GstFormatter.formatIndianCurrency(res.sgstAmount), isDarkMode, isSubItem: true),
            ],
            
            // Conditional igst rows
            if (res.calculationType == 'IGST' || res.igstAmount > 0) ...[
              _buildResultRow('IGST (Integrated GST)', GstFormatter.formatIndianCurrency(res.igstAmount), isDarkMode, isSubItem: true),
            ],

            SizedBox(height: 12.h),
            const Divider(),
            SizedBox(height: 8.h),
            
            // Final Amount Row (Highlighted)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Final Amount',
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  GstFormatter.formatIndianCurrency(res.finalAmount),
                  style: GoogleFonts.firaCode(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Copy, Share, Print Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  onTap: () => _copyToClipboard(context),
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                _buildActionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () {
                    _copyToClipboard(context);
                  },
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                _buildActionButton(
                  icon: Icons.local_printshop_rounded,
                  label: 'Print',
                  onTap: () => _showPrintPreview(context),
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
            
            SizedBox(height: 12.h),
            
            // Toggleable Formula Section
            InkWell(
              onTap: () {
                setState(() {
                  _showSteps = !_showSteps;
                });
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _showSteps ? 'Hide Formula & Steps' : 'View Formula & Steps',
                      style: GoogleFonts.outfit(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Icon(
                      _showSteps ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: primaryColor,
                      size: 18.r,
                    ),
                  ],
                ),
              ),
            ),
            
            // Animated Expansion
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showSteps
                  ? Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: GstFormulaSheet(result: res),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value,
    bool isDarkMode, {
    Color? highlightColor,
    bool isSubItem = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: isSubItem ? 12.w : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: isSubItem ? 12.sp : 13.sp,
              fontWeight: isSubItem ? FontWeight.w500 : FontWeight.w600,
              color: isSubItem
                  ? (isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B))
                  : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.firaCode(
              fontSize: isSubItem ? 12.sp : 13.sp,
              fontWeight: isSubItem ? FontWeight.w500 : FontWeight.bold,
              color: highlightColor ?? (isDarkMode ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20.r),
            SizedBox(height: 4.h),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11.sp,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
