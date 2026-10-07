import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../models/tax_result_model.dart';
import '../utils/tax_formatter.dart';
import '../constants/tax_constants.dart';

class TaxPrintPreviewDialog extends StatelessWidget {
  final TaxResultModel result;

  const TaxPrintPreviewDialog({
    super.key,
    required this.result,
  });

  /// Compile formatted text string
  String _generatePlainTextReport() {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('     CIRCUITPOINT TAX REPORT            ');
    buffer.writeln('========================================');
    buffer.writeln('Date: ${TaxFormatter.formatDate(result.createdAt)}');
    buffer.writeln('Type: ${TaxConstants.name}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Original Amount : ${TaxFormatter.formatIndianCurrency(result.originalAmount)}');
    buffer.writeln('Tax Percentage  : ${TaxFormatter.formatPercentage(result.taxPercentage)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Tax Amount      : ${TaxFormatter.formatIndianCurrency(result.taxAmount)}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('FINAL AMOUNT    : ${TaxFormatter.formatIndianCurrency(result.finalAmount)}');
    buffer.writeln('========================================');
    buffer.writeln('Generated via Enquiry App Tax Module   ');
    buffer.writeln('========================================');
    return buffer.toString();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generatePlainTextReport()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tax report copied!'),
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
                            'TAX CALCULATION STATEMENT',
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

                    _buildReceiptRow('Date & Time', TaxFormatter.formatDate(result.createdAt)),
                    _buildReceiptRow('Tax Calculator', TaxConstants.name),
                    const Divider(color: Colors.black38),
                    _buildReceiptRow('Original Amount', TaxFormatter.formatIndianCurrency(result.originalAmount)),
                    _buildReceiptRow('Tax Percentage', TaxFormatter.formatPercentage(result.taxPercentage)),
                    const Divider(color: Colors.black38),
                    _buildReceiptRow('Tax Amount', TaxFormatter.formatIndianCurrency(result.taxAmount), isBold: true),
                    _buildReceiptRow('FINAL AMOUNT', TaxFormatter.formatIndianCurrency(result.finalAmount), isBold: true, fontSize: 12.5.sp),

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
