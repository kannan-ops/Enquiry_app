import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/interest_constants.dart';

class InterestInputCard extends StatelessWidget {
  final int selectedTabIndex;
  
  final TextEditingController principalController;
  final TextEditingController rateController;
  final TextEditingController timeController;

  final String selectedTimeUnit;
  final ValueChanged<String> onTimeUnitChanged;

  final String selectedCompoundFrequency;
  final ValueChanged<String> onCompoundFrequencyChanged;

  final String? principalError;
  final String? rateError;
  final String? timeError;
  
  final bool isLoading;
  final VoidCallback onCalculate;
  final VoidCallback onReset;

  const InterestInputCard({
    super.key,
    required this.selectedTabIndex,
    required this.principalController,
    required this.rateController,
    required this.timeController,
    required this.selectedTimeUnit,
    required this.onTimeUnitChanged,
    required this.selectedCompoundFrequency,
    required this.onCompoundFrequencyChanged,
    required this.principalError,
    required this.rateError,
    required this.timeError,
    required this.isLoading,
    required this.onCalculate,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Determine dynamic labels & hints based on tab index
    String principalLabel = 'Principal Amount (₹)';
    String principalHint = 'Enter principal amount';
    String timeLabel = 'Time / Tenure';
    String timeHint = 'Enter time';
    bool showTimeUnitDropdown = false;
    bool showCompoundFrequencyDropdown = false;
    List<String> timeUnits = [];

    switch (selectedTabIndex) {
      case 0: // Simple Interest
        principalLabel = 'Principal Amount (₹)';
        principalHint = 'Enter principal sum';
        timeLabel = 'Time Period';
        timeHint = 'Enter period';
        showTimeUnitDropdown = true;
        timeUnits = interestTimeUnits;
        break;
      case 1: // Compound Interest
        principalLabel = 'Principal Amount (₹)';
        principalHint = 'Enter initial investment';
        timeLabel = 'Tenure (Years)';
        timeHint = 'Enter years';
        showCompoundFrequencyDropdown = true;
        break;
      case 2: // EMI Calculator
        principalLabel = 'Loan Amount (₹)';
        principalHint = 'Enter total loan borrowing';
        timeLabel = 'Loan Tenure';
        timeHint = 'Enter tenure';
        showTimeUnitDropdown = true;
        timeUnits = ['Years', 'Months'];
        break;
      case 3: // Fixed Deposit
        principalLabel = 'Deposit Amount (₹)';
        principalHint = 'Enter amount to deposit';
        timeLabel = 'Tenure (Years)';
        timeHint = 'Enter years';
        break;
      case 4: // Recurring Deposit
        principalLabel = 'Monthly Deposit (₹)';
        principalHint = 'Enter monthly saving sum';
        timeLabel = 'Tenure (Months)';
        timeHint = 'Enter months';
        break;
      case 5: // Daily Interest
        principalLabel = 'Amount (₹)';
        principalHint = 'Enter amount';
        timeLabel = 'Tenure (Days)';
        timeHint = 'Enter days';
        break;
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

            // Principal Input Field
            Text(
              principalLabel,
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: principalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.outfit(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: principalHint,
                errorText: principalError,
                prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                suffixIcon: principalController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => principalController.clear(),
                      )
                    : null,
              ),
            ),
            SizedBox(height: 16.h),

            // Interest Rate Input Field
            Text(
              'Interest Rate (% per annum)',
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.outfit(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Enter rate (e.g. 7.5)',
                errorText: rateError,
                prefixIcon: const Icon(Icons.percent_rounded, size: 18),
                suffixIcon: rateController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => rateController.clear(),
                      )
                    : null,
              ),
            ),
            SizedBox(height: 16.h),

            // Time / Tenure Input & Unit Dropdown Row
            Text(
              timeLabel,
              style: GoogleFonts.outfit(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input TextField
                Expanded(
                  flex: showTimeUnitDropdown ? 3 : 1,
                  child: TextField(
                    controller: timeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.outfit(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: timeHint,
                      errorText: timeError,
                      prefixIcon: const Icon(Icons.av_timer_rounded, size: 18),
                    ),
                  ),
                ),
                // Time Unit Dropdown (if applicable)
                if (showTimeUnitDropdown) ...[
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 54.h, // matches standard decoration size height
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedTimeUnit,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          dropdownColor: isDarkMode ? const Color(0xFF151B2C) : Colors.white,
                          items: timeUnits.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(
                                unit,
                                style: GoogleFonts.outfit(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) onTimeUnitChanged(value);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Compounding Frequency (For compound interest only)
            if (showCompoundFrequencyDropdown) ...[
              SizedBox(height: 16.h),
              Text(
                'Compounding Frequency',
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
                  child: DropdownButton<String>(
                    value: selectedCompoundFrequency,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    dropdownColor: isDarkMode ? const Color(0xFF151B2C) : Colors.white,
                    items: compoundingFrequencies.map((String freq) {
                      return DropdownMenuItem<String>(
                        value: freq,
                        child: Text(
                          freq,
                          style: GoogleFonts.outfit(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null) onCompoundFrequencyChanged(value);
                    },
                  ),
                ),
              ),
            ],

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
