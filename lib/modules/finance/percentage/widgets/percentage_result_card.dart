import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/percentage_result_model.dart';
import '../utils/percentage_formatter.dart';
import 'percentage_formula_sheet.dart';
import 'percentage_print_preview_dialog.dart';

class PercentageResultCard extends StatefulWidget {
  final PercentageResultModel result;

  const PercentageResultCard({
    super.key,
    required this.result,
  });

  @override
  State<PercentageResultCard> createState() => _PercentageResultCardState();
}

class _PercentageResultCardState extends State<PercentageResultCard> {
  bool _showSteps = false;

  String _generateShareText() {
    final res = widget.result;
    final buffer = StringBuffer();
    buffer.writeln('--- Percentage Calculation Details ---');
    buffer.writeln('Type: ${res.calculationType}');
    
    res.inputValues.forEach((key, val) {
      buffer.writeln('$key: ${_formatDisplayValue(key, val)}');
    });
    
    buffer.writeln('--------------------------------------');
    buffer.writeln('${_getResultLabel()}: ${_formatDisplayValue(_getResultLabel(), res.result)}');
    buffer.writeln('${_getPercentageLabel()}: ${_formatPercentageDisplay(res.percentage)}');
    buffer.writeln('Generated via CircuitPoint App');
    return buffer.toString();
  }

  String _formatDisplayValue(String key, double val) {
    final low = key.toLowerCase();
    if (low.contains('price') || low.contains('amount') || low.contains('cost') || low.contains('sale') || low.contains('profit') || low.contains('loss') || low.contains('discount') || low.contains('markup') || low.contains('commission')) {
      return PercentageFormatter.formatIndianCurrency(val);
    }
    final isInt = val == val.toInt();
    return isInt ? val.toInt().toString() : val.toStringAsFixed(2);
  }

  String _formatPercentageDisplay(double val) {
    if (widget.result.calculationType == 'Discount Calculator' || widget.result.calculationType == 'Markup Calculator' || widget.result.calculationType == 'Commission Calculator') {
      return PercentageFormatter.formatIndianCurrency(val);
    }
    return PercentageFormatter.formatPercentage(val);
  }

  String _getResultLabel() {
    switch (widget.result.calculationType) {
      case 'Percentage of Number':
        return 'Value Output';
      case 'What Percentage?':
        return 'Value Part';
      case 'Percentage Increase':
      case 'Percentage Decrease':
      case 'Percentage Change':
        return 'Absolute Diff';
      case 'Profit Percentage':
        return 'Profit Amount';
      case 'Loss Percentage':
        return 'Loss Amount';
      case 'Discount Calculator':
        return 'Final Price';
      case 'Markup Calculator':
        return 'Selling Price';
      case 'Margin Calculator':
        return 'Profit Sum';
      case 'Commission Calculator':
        return 'Net Payout';
      default:
        return 'Calculated Value';
    }
  }

  String _getPercentageLabel() {
    switch (widget.result.calculationType) {
      case 'Percentage of Number':
        return 'Factor Rate';
      case 'What Percentage?':
        return 'Percentage %';
      case 'Percentage Increase':
        return 'Increase %';
      case 'Percentage Decrease':
        return 'Decrease %';
      case 'Percentage Difference':
        return 'Difference %';
      case 'Profit Percentage':
        return 'Profit %';
      case 'Loss Percentage':
        return 'Loss %';
      case 'Discount Calculator':
        return 'Savings Amount';
      case 'Markup Calculator':
        return 'Markup Amount';
      case 'Margin Calculator':
        return 'Profit Margin %';
      case 'Percentage Change':
        return 'Change %';
      case 'Commission Calculator':
        return 'Commission Earned';
      default:
        return 'Rate %';
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generateShareText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calculation copied!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPrintPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PercentagePrintPreviewDialog(result: widget.result),
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
                    res.calculationType,
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

            // Dynamic Inputs list
            ...res.inputValues.entries.map((e) {
              return _buildResultRow(e.key, _formatDisplayValue(e.key, e.value), isDarkMode);
            }),
            
            _buildResultRow(_getResultLabel(), _formatDisplayValue(_getResultLabel(), res.result), isDarkMode),
            
            SizedBox(height: 12.h),
            const Divider(),
            SizedBox(height: 8.h),
            
            // Highlighted final output
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getPercentageLabel(),
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatPercentageDisplay(res.percentage),
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
            
            // Expand Steps trigger
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
                      child: PercentageFormulaSheet(result: res),
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
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
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
