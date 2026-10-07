import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../models/interest_result_model.dart';
import '../utils/interest_formatter.dart';

class InterestPrintPreviewDialog extends StatelessWidget {
  final InterestResultModel result;

  const InterestPrintPreviewDialog({
    super.key,
    required this.result,
  });

  /// Formats plain text statement.
  String _generatePlainTextReport() {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('     CIRCUITPOINT FINANCE REPORT        ');
    buffer.writeln('========================================');
    buffer.writeln('Date: ${InterestFormatter.formatDate(result.createdAt)}');
    buffer.writeln('Type: ${result.calculationType}');
    buffer.writeln('----------------------------------------');
    
    // Principal Label adaptation
    String pLabel = 'Principal Amount';
    if (result.calculationType == 'EMI') pLabel = 'Loan Amount     ';
    if (result.calculationType == 'Fixed Deposit') pLabel = 'Deposit Amount  ';
    if (result.calculationType == 'Recurring Deposit') pLabel = 'Monthly Saved   ';
    
    // Total Principal value (RD principal is totalDeposit = monthly deposit * tenure)
    double pVal = result.principal;
    if (result.calculationType == 'Recurring Deposit') {
      pVal = result.principal / result.time;
    }
    
    buffer.writeln('$pLabel: ${InterestFormatter.formatIndianCurrency(pVal)}');
    buffer.writeln('Interest Rate   : ${result.interestRate}%');
    buffer.writeln('Time Period     : ${result.time} ${result.timeUnit}');
    
    if (result.compoundFrequency != null) {
      buffer.writeln('Compounding     : ${result.compoundFrequency}');
    }
    
    buffer.writeln('----------------------------------------');
    
    if (result.calculationType == 'Recurring Deposit') {
      buffer.writeln('Total Deposited : ${InterestFormatter.formatIndianCurrency(result.principal)}');
    }
    
    if (result.emi > 0) {
      if (result.calculationType == 'Daily Interest') {
        buffer.writeln('Daily Interest  : ${InterestFormatter.formatIndianCurrency(result.emi)}');
      } else {
        buffer.writeln('Monthly EMI     : ${InterestFormatter.formatIndianCurrency(result.emi)}');
      }
    }
    
    buffer.writeln('Interest Earned : ${InterestFormatter.formatIndianCurrency(result.interestAmount)}');
    
    if (result.maturityAmount > 0) {
      buffer.writeln('Maturity Amount : ${InterestFormatter.formatIndianCurrency(result.maturityAmount)}');
    }
    
    buffer.writeln('----------------------------------------');
    buffer.writeln('TOTAL REPAYMENT : ${InterestFormatter.formatIndianCurrency(result.totalAmount)}');
    buffer.writeln('========================================');
    buffer.writeln('Generated via Enquiry App Interest Mod ');
    buffer.writeln('========================================');
    return buffer.toString();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generatePlainTextReport()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finance report copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E);
    
    final pVal = result.calculationType == 'Recurring Deposit' 
        ? result.principal / result.time 
        : result.principal;
        
    final pLabel = result.calculationType == 'EMI' 
        ? 'Loan Amount' 
        : (result.calculationType == 'Fixed Deposit' ? 'Deposit Amount' : (result.calculationType == 'Recurring Deposit' ? 'Monthly Deposit' : 'Principal Amount'));
        
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
              // Header
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
                            'FINANCE CALCULATION STATEMENT',
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

                    _buildReceiptRow('Date & Time', InterestFormatter.formatDate(result.createdAt)),
                    _buildReceiptRow('Statement Type', result.calculationType),
                    
                    const Divider(color: Colors.black38, thickness: 1),
                    SizedBox(height: 8.h),

                    _buildReceiptRow(pLabel, InterestFormatter.formatIndianCurrency(pVal), isBold: true),
                    _buildReceiptRow('Annual Rate (%)', '${result.interestRate}%'),
                    _buildReceiptRow('Tenure', '${result.time} ${result.timeUnit}'),
                    
                    if (result.compoundFrequency != null) ...[
                      _buildReceiptRow('Compounding', result.compoundFrequency!),
                    ],
                    
                    if (result.calculationType == 'Recurring Deposit') ...[
                      _buildReceiptRow('Total Deposited', InterestFormatter.formatIndianCurrency(result.principal)),
                    ],

                    if (result.emi > 0) ...[
                      _buildReceiptRow(
                        result.calculationType == 'Daily Interest' ? 'Daily Interest' : 'Monthly EMI',
                        InterestFormatter.formatIndianCurrency(result.emi),
                        isBold: true,
                      ),
                    ],

                    _buildReceiptRow('Total Interest Earned/Payable', InterestFormatter.formatIndianCurrency(result.interestAmount)),
                    
                    if (result.maturityAmount > 0) ...[
                      _buildReceiptRow('Maturity Amount', InterestFormatter.formatIndianCurrency(result.maturityAmount), isBold: true),
                    ],
                    
                    SizedBox(height: 8.h),
                    const Divider(color: Colors.black38, thickness: 1),
                    SizedBox(height: 8.h),

                    _buildReceiptRow(
                      result.calculationType == 'EMI' ? 'TOTAL PAYMENT' : 'TOTAL RETURN AMOUNT',
                      InterestFormatter.formatIndianCurrency(result.totalAmount),
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
