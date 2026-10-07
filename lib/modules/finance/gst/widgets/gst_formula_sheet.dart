import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/gst_result_model.dart';
import '../utils/gst_formatter.dart';

class GstFormulaSheet extends StatelessWidget {
  final GstResultModel result;

  const GstFormulaSheet({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Determine info based on calculation type
    String formulaTitle = '';
    List<String> formulas = [];
    List<String> steps = [];

    final originalStr = GstFormatter.formatIndianCurrency(result.originalAmount);
    final finalStr = GstFormatter.formatIndianCurrency(result.finalAmount);
    final gstAmountStr = GstFormatter.formatIndianCurrency(result.gstAmount);
    final rateStr = '${result.gstPercentage}%';
    final rateDecimal = (result.gstPercentage / 100).toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

    switch (result.calculationType) {
      case 'Exclusive':
        formulaTitle = 'GST Exclusive (Add GST)';
        formulas = [
          'GST Amount = Amount × (GST % / 100)',
          'Final Amount = Amount + GST Amount',
        ];
        steps = [
          '1. Convert GST Rate to decimal: $rateStr / 100 = $rateDecimal',
          '2. Calculate GST Amount: $originalStr × $rateDecimal = $gstAmountStr',
          '3. Calculate Final Amount: $originalStr + $gstAmountStr = $finalStr',
        ];
        break;
      case 'Inclusive':
        formulaTitle = 'GST Inclusive (Remove GST)';
        formulas = [
          'Original Amount = Total Amount / (1 + (GST % / 100))',
          'GST Amount = Total Amount − Original Amount',
        ];
        steps = [
          '1. Calculate division factor: 1 + ($rateStr / 100) = ${(1 + result.gstPercentage / 100).toStringAsFixed(4)}',
          '2. Extract Original Amount: $finalStr / ${(1 + result.gstPercentage / 100).toStringAsFixed(4)} = $originalStr',
          '3. Calculate GST Amount: $finalStr − $originalStr = $gstAmountStr',
        ];
        break;
      case 'CGST + SGST':
        formulaTitle = 'CGST + SGST (Intra-State GST)';
        final cgstStr = GstFormatter.formatIndianCurrency(result.cgstAmount);
        final sgstStr = GstFormatter.formatIndianCurrency(result.sgstAmount);
        formulas = [
          'Total GST Amount = Amount × (GST % / 100)',
          'CGST Amount = Total GST Amount / 2',
          'SGST Amount = Total GST Amount / 2',
          'Final Amount = Amount + Total GST Amount',
        ];
        steps = [
          '1. Convert GST Rate to decimal: $rateStr / 100 = $rateDecimal',
          '2. Calculate Total GST Amount: $originalStr × $rateDecimal = $gstAmountStr',
          '3. Split into CGST & SGST (50% each):',
          '   - CGST = $gstAmountStr / 2 = $cgstStr',
          '   - SGST = $gstAmountStr / 2 = $sgstStr',
          '4. Calculate Final Amount: $originalStr + $gstAmountStr = $finalStr',
        ];
        break;
      case 'IGST':
        formulaTitle = 'IGST (Inter-State GST)';
        final igstStr = GstFormatter.formatIndianCurrency(result.igstAmount);
        formulas = [
          'IGST Amount = Amount × (GST % / 100)',
          'Final Amount = Amount + IGST Amount',
        ];
        steps = [
          '1. Convert GST Rate to decimal: $rateStr / 100 = $rateDecimal',
          '2. Calculate IGST Amount (100% of GST): $originalStr × $rateDecimal = $igstStr',
          '3. Calculate Final Amount: $originalStr + $igstStr = $finalStr',
        ];
        break;
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155).withOpacity(0.5) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 20.r,
                color: isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
              ),
              SizedBox(width: 8.w),
              Text(
                'Formula & Calculation Steps',
                style: GoogleFonts.outfit(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          
          // Calculation Type
          Text(
            'Type: $formulaTitle',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
            ),
          ),
          SizedBox(height: 8.h),
          const Divider(height: 12),
          
          // Formula Section
          Text(
            'Math Formulas:',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
          SizedBox(height: 4.h),
          ...formulas.map(
            (f) => Padding(
              padding: EdgeInsets.only(left: 8.w, top: 2.h),
              child: Text(
                '• $f',
                style: GoogleFonts.firaCode(
                  fontSize: 11.sp,
                  color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          SizedBox(height: 12.h),
          
          // Steps Section
          Text(
            'Step-by-Step Calculation:',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
          SizedBox(height: 4.h),
          ...steps.map(
            (s) => Padding(
              padding: EdgeInsets.only(left: 8.w, top: 4.h),
              child: Text(
                s,
                style: GoogleFonts.outfit(
                  fontSize: 12.sp,
                  color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
