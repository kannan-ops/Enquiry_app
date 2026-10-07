import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/gst_rates.dart';

class GstInputCard extends StatelessWidget {
  final TextEditingController amountController;
  final double selectedGstRate;
  final ValueChanged<double> onGstRateChanged;
  final String? validationError;
  final bool isLoading;
  final VoidCallback onCalculate;
  final VoidCallback onReset;
  final int selectedTab;

  const GstInputCard({
    super.key,
    required this.amountController,
    required this.selectedGstRate,
    required this.onGstRateChanged,
    required this.validationError,
    required this.isLoading,
    required this.onCalculate,
    required this.onReset,
    required this.selectedTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Determine the hint text based on the active tab
    String amountLabel = 'Amount (₹)';
    String amountHint = 'Enter base amount';
    if (selectedTab == 1) {
      amountLabel = 'Total Amount (₹)';
      amountHint = 'Enter total GST-inclusive amount';
    }

    return Card(
      elevation: isDarkMode ? 0 : 2,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculation Parameters',
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 16.h),
            
            // Amount Input Field
            Text(
              amountLabel,
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.outfit(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: amountHint,
                errorText: validationError,
                prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
                suffixIcon: amountController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          amountController.clear();
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                // To dynamically show/hide the clear button, trigger rebuilds if necessary,
                // but since it's a stateless widget, parent will handle it if needed.
              },
            ),
            SizedBox(height: 20.h),

            // GST Percentage Dropdown
            Text(
              'GST Rate (%)',
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: selectedGstRate,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  dropdownColor: isDarkMode ? const Color(0xFF151B2C) : Colors.white,
                  items: gstRates.map((double rate) {
                    final isInt = rate == rate.toInt();
                    final rateString = isInt ? '${rate.toInt()}%' : '$rate%';
                    return DropdownMenuItem<double>(
                      value: rate,
                      child: Text(
                        rateString,
                        style: GoogleFonts.outfit(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (double? newValue) {
                    if (newValue != null) {
                      onGstRateChanged(newValue);
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 24.h),

            // Action Buttons
            Row(
              children: [
                // Reset Button
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
                // Calculate Button
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onCalculate,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
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
