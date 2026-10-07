import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gst_result_model.dart';
import '../utils/gst_formatter.dart';

class GstPrintPreviewDialog extends StatelessWidget {
  final GstResultModel result;

  const GstPrintPreviewDialog({
    super.key,
    required this.result,
  });

  /// Generates the plain text representation of the calculation report.
  String _generatePlainTextReport() {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('     CIRCUITPOINT GST REPORT            ');
    buffer.writeln('========================================');
    buffer.writeln('Date: ${GstFormatter.formatDate(result.createdAt)}');
    buffer.writeln('Type: ${result.calculationType}');
    buffer.writeln('----------------------------------------');
    buffer.writeln('Original Amount : ${GstFormatter.formatIndianCurrency(result.originalAmount)}');
    buffer.writeln('GST Rate        : ${result.gstPercentage}%');
    buffer.writeln('GST Amount      : ${GstFormatter.formatIndianCurrency(result.gstAmount)}');
    
    if (result.cgstAmount > 0 || result.calculationType == 'CGST + SGST') {
      buffer.writeln('CGST (50% of GST): ${GstFormatter.formatIndianCurrency(result.cgstAmount)}');
      buffer.writeln('SGST (50% of GST): ${GstFormatter.formatIndianCurrency(result.sgstAmount)}');
    }
    
    if (result.igstAmount > 0 || result.calculationType == 'IGST') {
      buffer.writeln('IGST            : ${GstFormatter.formatIndianCurrency(result.igstAmount)}');
    }
    
    buffer.writeln('----------------------------------------');
    buffer.writeln('Final Amount    : ${GstFormatter.formatIndianCurrency(result.finalAmount)}');
    buffer.writeln('========================================');
    buffer.writeln('Generated via Enquiry App GST Module    ');
    buffer.writeln('========================================');
    return buffer.toString();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generatePlainTextReport()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E);
    
    // Receipt table fields
    final originalStr = GstFormatter.formatIndianCurrency(result.originalAmount);
    final finalStr = GstFormatter.formatIndianCurrency(result.finalAmount);
    final gstAmountStr = GstFormatter.formatIndianCurrency(result.gstAmount);
    final rateStr = '${result.gstPercentage}%';
    
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
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Print Preview',
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

              // Printable Receipt Layout (High Contrast Monochrome Card)
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
                            'GST CALCULATION STATEMENT',
                            style: GoogleFonts.outfit(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    
                    // Receipt Dotted Divider
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

                    // Header Info
                    _buildReceiptRow('Date & Time', GstFormatter.formatDate(result.createdAt)),
                    _buildReceiptRow('Calculation Type', result.calculationType),
                    SizedBox(height: 12.h),
                    
                    // Receipt Solid Line
                    const Divider(color: Colors.black38, thickness: 1),
                    SizedBox(height: 8.h),

                    // Values
                    _buildReceiptRow('Original Amount', originalStr, isBold: true),
                    _buildReceiptRow('GST Percentage', rateStr),
                    _buildReceiptRow('GST Amount', gstAmountStr),
                    
                    if (result.cgstAmount > 0 || result.calculationType == 'CGST + SGST') ...[
                      _buildReceiptRow('CGST (50% of GST)', GstFormatter.formatIndianCurrency(result.cgstAmount)),
                      _buildReceiptRow('SGST (50% of GST)', GstFormatter.formatIndianCurrency(result.sgstAmount)),
                    ],
                    if (result.igstAmount > 0 || result.calculationType == 'IGST') ...[
                      _buildReceiptRow('IGST Amount', GstFormatter.formatIndianCurrency(result.igstAmount)),
                    ],
                    
                    SizedBox(height: 8.h),
                    const Divider(color: Colors.black38, thickness: 1),
                    SizedBox(height: 8.h),
                    
                    _buildReceiptRow('FINAL AMOUNT', finalStr, isBold: true, fontSize: 14.sp),
                    
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

              // Action buttons
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
                        // In Flutter, sharing plain text is standard. We can copy first and prompt the user.
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
