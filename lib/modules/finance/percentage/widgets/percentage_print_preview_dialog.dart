import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../models/percentage_result_model.dart';
import '../utils/percentage_formatter.dart';

class PercentagePrintPreviewDialog extends StatelessWidget {
  final PercentageResultModel result;

  const PercentagePrintPreviewDialog({
    super.key,
    required this.result,
  });

  /// Compile formatted text string
  String _generatePlainTextReport() {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('     CIRCUITPOINT PERCENTAGE REPORT     ');
    buffer.writeln('========================================');
    buffer.writeln('Date: ${PercentageFormatter.formatDate(result.createdAt)}');
    buffer.writeln('Type: ${result.calculationType}');
    buffer.writeln('----------------------------------------');
    
    // Write dynamic inputs
    result.inputValues.forEach((key, value) {
      final keyPadded = key.padRight(16);
      final valFormatted = _formatReceiptValue(key, value);
      buffer.writeln('$keyPadded: $valFormatted');
    });
    
    buffer.writeln('----------------------------------------');
    
    // Output values
    final resLabel = _getResultLabel().padRight(16);
    final pctLabel = _getPercentageLabel().padRight(16);
    
    buffer.writeln('$resLabel: ${_formatReceiptValue(_getResultLabel(), result.result)}');
    buffer.writeln('$pctLabel: ${PercentageFormatter.formatPercentage(result.percentage)}');
    buffer.writeln('========================================');
    buffer.writeln('Generated via Enquiry App Percentage Mod');
    buffer.writeln('========================================');
    return buffer.toString();
  }

  String _formatReceiptValue(String key, double val) {
    final low = key.toLowerCase();
    if (low.contains('price') || low.contains('amount') || low.contains('cost') || low.contains('sale') || low.contains('profit') || low.contains('loss') || low.contains('discount') || low.contains('markup') || low.contains('commission')) {
      return PercentageFormatter.formatIndianCurrency(val);
    }
    final isInt = val == val.toInt();
    return isInt ? val.toInt().toString() : val.toStringAsFixed(2);
  }

  String _getResultLabel() {
    switch (result.calculationType) {
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
    switch (result.calculationType) {
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
        return 'Saved Amount';
      case 'Markup Calculator':
        return 'Added Amount';
      case 'Margin Calculator':
        return 'Profit Margin %';
      case 'Percentage Change':
        return 'Change %';
      case 'Commission Calculator':
        return 'Earned Comm';
      default:
        return 'Rate %';
    }
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generatePlainTextReport()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Percentage report copied!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      backgroundColor: isDarkMode ? const Color(0xFF0A0F1D) : Colors.white,
      child: Container(
        constraints: BoxConstraints(maxWidth: 400.w),
        padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Receipt Statement',
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              SizedBox(height: 12.h),

              // Printable receipt card
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.black12, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'CIRCUITPOINT',
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            'PERCENTAGE STATEMENT',
                            style: GoogleFonts.outfit(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    
                    Row(
                      children: List.generate(
                        30,
                        (index) => Expanded(
                          child: Container(
                            color: index % 2 == 0 ? Colors.transparent : Colors.black38,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    _buildReceiptRow('Date & Time', PercentageFormatter.formatDate(result.createdAt)),
                    _buildReceiptRow('Calculation Mode', result.calculationType),
                    
                    const Divider(color: Colors.black38, thickness: 1),
                    SizedBox(height: 8.h),

                    // Inputs list
                    ...result.inputValues.entries.map((e) {
                      return _buildReceiptRow(e.key, _formatReceiptValue(e.key, e.value));
                    }),
                    
                    SizedBox(height: 8.h),
                    const Divider(color: Colors.black38, thickness: 1),
                    SizedBox(height: 8.h),

                    // Result outputs
                    _buildReceiptRow(_getResultLabel(), _formatReceiptValue(_getResultLabel(), result.result), isBold: true),
                    _buildReceiptRow(
                      _getPercentageLabel(),
                      _formatPercentageDisplay(result.percentage),
                      isBold: true,
                      fontSize: 12.5.sp,
                    ),

                    SizedBox(height: 16.h),
                    Row(
                      children: List.generate(
                        30,
                        (index) => Expanded(
                          child: Container(
                            color: index % 2 == 0 ? Colors.transparent : Colors.black38,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    Center(
                      child: Text(
                        'Thank you for using CircuitPoint',
                        style: GoogleFonts.outfit(
                          fontSize: 9.sp,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_all_rounded, size: 18),
                      label: const Text('Copy Text'),
                      onPressed: () => _copyToClipboard(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share'),
                      onPressed: () {
                        _copyToClipboard(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPercentageDisplay(double val) {
    if (result.calculationType == 'Discount Calculator' || result.calculationType == 'Markup Calculator' || result.calculationType == 'Commission Calculator') {
      return PercentageFormatter.formatIndianCurrency(val);
    }
    return PercentageFormatter.formatPercentage(val);
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, double? fontSize}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: fontSize ?? 11.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.firaCode(
              fontSize: fontSize ?? 11.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
