import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tax_result_model.dart';
import '../utils/tax_formatter.dart';
import '../constants/tax_constants.dart';

class TaxFormulaSheet extends StatelessWidget {
  final TaxResultModel result;

  const TaxFormulaSheet({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final double base = result.originalAmount;
    final double rate = result.taxPercentage;
    final double tax = result.taxAmount;
    final double total = result.finalAmount;

    final String baseStr = base.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    final String rateStr = rate.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    final String taxStr = tax.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    final String totalStr = total.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');

    final List<String> formulas = [
      'Tax Amount = Base Amount × Tax Rate (%) ÷ 100',
      'Final Amount = Base Amount + Tax Amount',
    ];

    final List<String> steps = [
      '1. Divide percentage value by 100: $rateStr / 100 = ${(rate / 100).toStringAsFixed(4)}',
      '2. Multiply by the base amount: $baseStr × ${(rate / 100).toStringAsFixed(4)} = $taxStr (Tax Amount)',
      '3. Add tax amount to original base: $baseStr + $taxStr = $totalStr (Final Amount)',
    ];

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
          
          Text(
            'Type: ${TaxConstants.name}',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
            ),
          ),
          SizedBox(height: 8.h),
          const Divider(height: 12),
          
          Text(
            'Formulas:',
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
                  fontSize: 10.5.sp,
                  color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          SizedBox(height: 12.h),
          
          Text(
            'Step-by-Step Breakdown:',
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
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
