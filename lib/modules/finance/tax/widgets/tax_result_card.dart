import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tax_result_model.dart';
import '../utils/tax_formatter.dart';
import 'tax_formula_sheet.dart';
import 'tax_print_preview_dialog.dart';

class TaxResultCard extends StatefulWidget {
  final TaxResultModel result;

  const TaxResultCard({
    super.key,
    required this.result,
  });

  @override
  State<TaxResultCard> createState() => _TaxResultCardState();
}

class _TaxResultCardState extends State<TaxResultCard> {
  bool _showSteps = false;

  String _generateShareText() {
    final res = widget.result;
    final buffer = StringBuffer();
    buffer.writeln('--- Tax Calculation Details ---');
    buffer.writeln('Original Amount : ${TaxFormatter.formatIndianCurrency(res.originalAmount)}');
    buffer.writeln('Tax Percentage  : ${TaxFormatter.formatPercentage(res.taxPercentage)}');
    buffer.writeln('Tax Amount      : ${TaxFormatter.formatIndianCurrency(res.taxAmount)}');
    buffer.writeln('Final Amount    : ${TaxFormatter.formatIndianCurrency(res.finalAmount)}');
    buffer.writeln('Generated via CircuitPoint App');
    return buffer.toString();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generateShareText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax calculation copied!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPrintPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TaxPrintPreviewDialog(result: widget.result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                    'Custom Tax',
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            _buildResultRow('Original Amount', TaxFormatter.formatIndianCurrency(res.originalAmount), isDarkMode),
            _buildResultRow('Tax Percentage', TaxFormatter.formatPercentage(res.taxPercentage), isDarkMode),
            _buildResultRow('Tax Amount', TaxFormatter.formatIndianCurrency(res.taxAmount), isDarkMode, highlightColor: primaryColor),
            
            SizedBox(height: 12.h),
            const Divider(),
            SizedBox(height: 8.h),
            
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
                  TaxFormatter.formatIndianCurrency(res.finalAmount),
                  style: GoogleFonts.firaCode(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Actions Copy, Share, Print
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
                  onTap: () => _copyToClipboard(context),
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
            
            // Toggle steps expander
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
            
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showSteps
                  ? Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: TaxFormulaSheet(result: widget.result),
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
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.firaCode(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
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
