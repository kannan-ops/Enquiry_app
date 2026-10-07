import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/percentage_result_model.dart';
import '../utils/percentage_formatter.dart';

class PercentageFormulaSheet extends StatelessWidget {
  final PercentageResultModel result;

  const PercentageFormulaSheet({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final keys = result.inputValues.keys.toList();
    final double val1 = keys.isNotEmpty ? result.inputValues[keys[0]]! : 0.0;
    final double val2 = keys.length > 1 ? result.inputValues[keys[1]]! : 0.0;

    final String val1Str = val1.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    final String val2Str = val2.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');

    final resultStr = result.result.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    final percentStr = PercentageFormatter.formatPercentage(result.percentage);

    List<String> formulas = [result.formula];
    List<String> steps = [];

    switch (result.calculationType) {
      case 'Percentage of Number':
        steps = [
          '1. Divide percentage value by 100: $val2Str / 100 = ${(val2 / 100).toStringAsFixed(4)}',
          '2. Multiply by the base number: $val1Str × ${(val2 / 100).toStringAsFixed(4)} = $resultStr',
          '3. Thus, $val2Str% of $val1Str is $resultStr.',
        ];
        break;

      case 'What Percentage?':
        steps = [
          '1. Divide value by total value: $val1Str / $val2Str = ${(val1 / val2).toStringAsFixed(6)}',
          '2. Multiply by 100 to get percentage: ${(val1 / val2).toStringAsFixed(6)} × 100 = $percentStr',
          '3. Thus, $val1Str is $percentStr of $val2Str.',
        ];
        break;

      case 'Percentage Increase':
        final diff = val2 - val1;
        steps = [
          '1. Calculate absolute increase: $val2Str (New) − $val1Str (Old) = ${diff.toStringAsFixed(2)}',
          '2. Divide increase by original old value: ${diff.toStringAsFixed(2)} / $val1Str = ${(diff / val1).toStringAsFixed(6)}',
          '3. Multiply by 100 to get percentage growth: ${(diff / val1).toStringAsFixed(6)} × 100 = $percentStr',
        ];
        break;

      case 'Percentage Decrease':
        final diff = val1 - val2;
        steps = [
          '1. Calculate absolute decrease: $val1Str (Old) − $val2Str (New) = ${diff.toStringAsFixed(2)}',
          '2. Divide decrease by original old value: ${diff.toStringAsFixed(2)} / $val1Str = ${(diff / val1).toStringAsFixed(6)}',
          '3. Multiply by 100 to get percentage shrink: ${(diff / val1).toStringAsFixed(6)} × 100 = $percentStr',
        ];
        break;

      case 'Percentage Difference':
        final diff = (val1 - val2).abs();
        final avg = (val1 + val2) / 2;
        steps = [
          '1. Calculate absolute difference: |$val1Str − $val2Str| = ${diff.toStringAsFixed(2)}',
          '2. Calculate average of values: ($val1Str + $val2Str) / 2 = ${avg.toStringAsFixed(2)}',
          '3. Divide difference by average: ${diff.toStringAsFixed(2)} / ${avg.toStringAsFixed(2)} = ${(diff / avg).toStringAsFixed(6)}',
          '4. Multiply by 100 to get percentage difference: ${(diff / avg).toStringAsFixed(6)} × 100 = $percentStr',
        ];
        break;

      case 'Profit Percentage':
        final profit = val2 - val1;
        steps = [
          '1. Calculate profit amount: SP ($val2Str) − CP ($val1Str) = ${profit.toStringAsFixed(2)}',
          '2. Divide profit by cost price (CP): ${profit.toStringAsFixed(2)} / $val1Str = ${(profit / val1).toStringAsFixed(6)}',
          '3. Multiply by 100 to get profit percentage: ${(profit / val1).toStringAsFixed(6)} × 100 = $percentStr',
        ];
        break;

      case 'Loss Percentage':
        final loss = val1 - val2;
        steps = [
          '1. Calculate loss amount: CP ($val1Str) − SP ($val2Str) = ${loss.toStringAsFixed(2)}',
          '2. Divide loss by cost price (CP): ${loss.toStringAsFixed(2)} / $val1Str = ${(loss / val1).toStringAsFixed(6)}',
          '3. Multiply by 100 to get loss percentage: ${(loss / val1).toStringAsFixed(6)} × 100 = $percentStr',
        ];
        break;

      case 'Discount Calculator':
        final savings = val1 * val2 / 100;
        steps = [
          '1. Calculate savings: Price ($val1Str) × Discount ($val2Str%) / 100 = ${savings.toStringAsFixed(2)}',
          '2. Subtract savings from original price: $val1Str − ${savings.toStringAsFixed(2)} = $resultStr',
          '3. Thus, final discounted price is $resultStr, saving you ${PercentageFormatter.formatIndianCurrency(savings)}.',
        ];
        break;

      case 'Markup Calculator':
        final markup = val1 * val2 / 100;
        steps = [
          '1. Calculate markup amount: Cost ($val1Str) × Markup ($val2Str%) / 100 = ${markup.toStringAsFixed(2)}',
          '2. Add markup amount to cost: $val1Str + ${markup.toStringAsFixed(2)} = $resultStr',
          '3. Thus, final selling price with markup is $resultStr.',
        ];
        break;

      case 'Margin Calculator':
        final profit = val2 - val1;
        steps = [
          '1. Calculate profit amount: SP ($val2Str) − CP ($val1Str) = ${profit.toStringAsFixed(2)}',
          '2. Divide profit by selling price (SP): ${profit.toStringAsFixed(2)} / $val2Str = ${(profit / val2).toStringAsFixed(6)}',
          '3. Multiply by 100 to get margin percentage: ${(profit / val2).toStringAsFixed(6)} × 100 = $percentStr',
        ];
        break;

      case 'Percentage Change':
        final change = val2 - val1;
        final direction = change >= 0 ? 'Increase' : 'Decrease';
        steps = [
          '1. Calculate absolute change: $val2Str (Revised) − $val1Str (Original) = ${change.toStringAsFixed(2)}',
          '2. Divide change by original value: ${change.toStringAsFixed(2)} / $val1Str = ${(change / val1).toStringAsFixed(6)}',
          '3. Multiply by 100 to get percentage change: ${(change / val1).toStringAsFixed(6)} × 100 = $percentStr ($direction)',
        ];
        break;

      case 'Commission Calculator':
        final comm = val1 * val2 / 100;
        steps = [
          '1. Calculate commission: Sale ($val1Str) × Commission ($val2Str%) / 100 = ${comm.toStringAsFixed(2)}',
          '2. Subtract commission from sale (for net payout): $val1Str − ${comm.toStringAsFixed(2)} = $resultStr',
          '3. Thus, commission earnings are ${PercentageFormatter.formatIndianCurrency(comm)} and net payout is $resultStr.',
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
          
          Text(
            'Type: ${result.calculationType}',
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
