import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/interest_result_model.dart';
import '../utils/interest_formatter.dart';
import 'interest_formula_sheet.dart';
import 'interest_print_preview_dialog.dart';

class InterestResultCard extends StatefulWidget {
  final InterestResultModel result;

  const InterestResultCard({
    super.key,
    required this.result,
  });

  @override
  State<InterestResultCard> createState() => _InterestResultCardState();
}

class _InterestResultCardState extends State<InterestResultCard> {
  bool _showSteps = false;

  String _generateShareText() {
    final res = widget.result;
    final buffer = StringBuffer();
    buffer.writeln('--- Interest Calculation details ---');
    buffer.writeln('Type: ${res.calculationType}');
    
    final pVal = res.calculationType == 'Recurring Deposit' 
        ? res.principal / res.time 
        : res.principal;
    final pLabel = res.calculationType == 'EMI' 
        ? 'Loan Amount' 
        : (res.calculationType == 'Fixed Deposit' ? 'Deposit Amount' : (res.calculationType == 'Recurring Deposit' ? 'Monthly Saving' : 'Principal Amount'));
        
    buffer.writeln('$pLabel: ${InterestFormatter.formatIndianCurrency(pVal)}');
    buffer.writeln('Annual Interest Rate: ${res.interestRate}%');
    buffer.writeln('Tenure: ${res.time} ${res.timeUnit}');
    if (res.compoundFrequency != null) {
      buffer.writeln('Compounding: ${res.compoundFrequency}');
    }
    if (res.calculationType == 'Recurring Deposit') {
      buffer.writeln('Total Saved: ${InterestFormatter.formatIndianCurrency(res.principal)}');
    }
    if (res.emi > 0) {
      buffer.writeln(res.calculationType == 'Daily Interest' ? 'Daily Interest Rate: ' : 'Monthly EMI: ' + InterestFormatter.formatIndianCurrency(res.emi));
    }
    buffer.writeln('Interest Earned: ${InterestFormatter.formatIndianCurrency(res.interestAmount)}');
    if (res.maturityAmount > 0) {
      buffer.writeln('Maturity Amount: ${InterestFormatter.formatIndianCurrency(res.maturityAmount)}');
    }
    buffer.writeln('Total Return Amount: ${InterestFormatter.formatIndianCurrency(res.totalAmount)}');
    buffer.writeln('Generated via CircuitPoint App');
    return buffer.toString();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _generateShareText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Finance calculation details copied!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPrintPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => InterestPrintPreviewDialog(result: widget.result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final res = widget.result;

    final primaryColor = isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E);
    
    // UI Label adaptation
    String pLabel = 'Principal Amount';
    if (res.calculationType == 'EMI') pLabel = 'Loan Amount';
    if (res.calculationType == 'Fixed Deposit') pLabel = 'Deposit Amount';
    if (res.calculationType == 'Recurring Deposit') pLabel = 'Monthly Saved';
    
    double pVal = res.principal;
    if (res.calculationType == 'Recurring Deposit') {
      pVal = res.principal / res.time;
    }
    
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
            // Title and badge
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

            // Rows of breakdowns
            _buildResultRow(pLabel, InterestFormatter.formatIndianCurrency(pVal), isDarkMode),
            _buildResultRow('Annual Rate', '${res.interestRate}%', isDarkMode),
            _buildResultRow('Tenure', '${res.time} ${res.timeUnit}', isDarkMode),
            
            if (res.compoundFrequency != null) ...[
              _buildResultRow('Compounding', res.compoundFrequency!, isDarkMode),
            ],
            
            if (res.calculationType == 'Recurring Deposit') ...[
              _buildResultRow('Total Invested', InterestFormatter.formatIndianCurrency(res.principal), isDarkMode),
            ],

            if (res.emi > 0) ...[
              _buildResultRow(
                res.calculationType == 'Daily Interest' ? 'Daily Interest Rate' : 'Monthly EMI',
                InterestFormatter.formatIndianCurrency(res.emi),
                isDarkMode,
                highlightColor: primaryColor,
              ),
            ],

            _buildResultRow(
              res.calculationType == 'EMI' ? 'Total Interest Payable' : 'Interest Earned',
              InterestFormatter.formatIndianCurrency(res.interestAmount),
              isDarkMode,
              highlightColor: primaryColor,
            ),
            
            if (res.maturityAmount > 0) ...[
              _buildResultRow('Maturity Amount', InterestFormatter.formatIndianCurrency(res.maturityAmount), isDarkMode),
            ],

            SizedBox(height: 12.h),
            const Divider(),
            SizedBox(height: 8.h),
            
            // Repayment/Maturity highlighted amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    res.calculationType == 'EMI' ? 'Total Repayment' : 'Maturity Value',
                    style: GoogleFonts.outfit(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  InterestFormatter.formatIndianCurrency(res.totalAmount),
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
                      child: InterestFormulaSheet(result: res),
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
