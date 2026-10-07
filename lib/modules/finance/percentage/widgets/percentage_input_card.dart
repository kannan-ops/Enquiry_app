import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/percentage_constants.dart';

class PercentageInputCard extends StatelessWidget {
  final int selectedTabIndex;
  
  final TextEditingController input1Controller;
  final TextEditingController input2Controller;

  final String? input1Error;
  final String? input2Error;
  
  final bool isLoading;
  final VoidCallback onCalculate;
  final VoidCallback onReset;

  const PercentageInputCard({
    super.key,
    required this.selectedTabIndex,
    required this.input1Controller,
    required this.input2Controller,
    required this.input1Error,
    required this.input2Error,
    required this.isLoading,
    required this.onCalculate,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Fetch configuration from meta constant
    final meta = percentageCalculatorsMeta[selectedTabIndex];
    final label1 = meta['input1Label'] as String;
    final hint1 = meta['input1Hint'] as String;
    final label2 = meta['input2Label'] as String;
    final hint2 = meta['input2Hint'] as String;
    final desc = meta['desc'] as String;

    // Check if we should display rupee icon for cost/selling prices
    final bool isCurrency1 = label1.contains('Price') || label1.contains('Cost') || label1.contains('Amount') || label1.contains('Sale');
    final bool isCurrency2 = label2.contains('Price') || label2.contains('Selling') || label2.contains('Amount');
    
    // Check if we should display percent icon
    final bool isPercent2 = label2.contains('%') || label2.contains('Percentage') || label2.contains('Discount') || label2.contains('Markup') || label2.contains('Commission');

    return Card(
      elevation: isDarkMode ? 0 : 2,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meta['name'] as String,
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              desc,
              style: GoogleFonts.outfit(
                fontSize: 11.5.sp,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 16.h),

            // Input 1
            Text(
              label1,
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: input1Controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: GoogleFonts.outfit(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint1,
                errorText: input1Error,
                prefixIcon: Icon(
                  isCurrency1 ? Icons.currency_rupee_rounded : Icons.numbers_rounded,
                  size: 18,
                ),
                suffixIcon: input1Controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => input1Controller.clear(),
                      )
                    : null,
              ),
            ),
            SizedBox(height: 16.h),

            // Input 2
            Text(
              label2,
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: input2Controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              style: GoogleFonts.outfit(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint2,
                errorText: input2Error,
                prefixIcon: Icon(
                  isPercent2
                      ? Icons.percent_rounded
                      : (isCurrency2 ? Icons.currency_rupee_rounded : Icons.numbers_rounded),
                  size: 18,
                ),
                suffixIcon: input2Controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => input2Controller.clear(),
                      )
                    : null,
              ),
            ),
            SizedBox(height: 24.h),

            // Reset and Calculate Actions
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onReset,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      side: BorderSide(
                        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: GoogleFonts.outfit(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onCalculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? SizedBox(
                            height: 20.r,
                            width: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Calculate',
                            style: GoogleFonts.outfit(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
