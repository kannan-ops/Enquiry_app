import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/interest_result_model.dart';
import '../utils/interest_formatter.dart';

class InterestFormulaSheet extends StatelessWidget {
  final InterestResultModel result;

  const InterestFormulaSheet({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    String title = '';
    List<String> formulas = [];
    List<String> steps = [];

    // Common formatted variables
    final pStr = InterestFormatter.formatIndianCurrency(result.principal);
    final rateStr = '${result.interestRate}%';
    final timeStr = '${result.time} ${result.timeUnit}';
    final interestStr = InterestFormatter.formatIndianCurrency(result.interestAmount);
    final totalStr = InterestFormatter.formatIndianCurrency(result.totalAmount);
    final emiStr = InterestFormatter.formatIndianCurrency(result.emi);
    final maturityStr = InterestFormatter.formatIndianCurrency(result.maturityAmount);

    switch (result.calculationType) {
      case 'Simple Interest':
        title = 'Simple Interest (SI)';
        formulas = [
          'SI = (P × R × T) / 100',
          'Total Amount = P + SI',
          'P = Principal, R = Rate %, T = Time in Years',
        ];
        
        double tInYears = result.time;
        String adjustmentExplain = '';
        if (result.timeUnit == 'Months') {
          tInYears = result.time / 12;
          adjustmentExplain = '   - Adjust months to years: ${result.time} / 12 = ${tInYears.toStringAsFixed(4)} years\n';
        } else if (result.timeUnit == 'Days') {
          tInYears = result.time / 365;
          adjustmentExplain = '   - Adjust days to years: ${result.time} / 365 = ${tInYears.toStringAsFixed(4)} years\n';
        }

        steps = [
          '1. Convert Time to Year unit if required:\n$adjustmentExplain   - Effective Time (T) = ${tInYears.toStringAsFixed(4)} years',
          '2. Calculate Interest: ($pStr × ${result.interestRate} × ${tInYears.toStringAsFixed(4)}) / 100 = $interestStr',
          '3. Calculate Total Amount: Principal + Interest\n   - $pStr + $interestStr = $totalStr',
        ];
        break;

      case 'Compound Interest':
        title = 'Compound Interest (CI)';
        final nText = result.compoundFrequency ?? 'Quarterly';
        formulas = [
          'Maturity Amount (A) = P × (1 + R / (N × 100))^(N × T)',
          'Interest Earned = A − P',
          'P = Principal, R = Annual Rate %, T = Years, N = Compounding Frequency per year',
        ];

        int nVal = 4;
        if (nText == 'Yearly') nVal = 1;
        if (nText == 'Half-Yearly') nVal = 2;
        if (nText == 'Quarterly') nVal = 4;
        if (nText == 'Monthly') nVal = 12;

        final periodicRate = (result.interestRate / (nVal * 100));
        final totalPeriods = nVal * result.time;

        steps = [
          '1. Identify Compounding Frequency (N): $nText (N = $nVal times/year)',
          '2. Compute periodic interest factor: 1 + (R / (N × 100))\n   - 1 + (${result.interestRate} / ($nVal × 100)) = ${(1 + periodicRate).toStringAsFixed(6)}',
          '3. Compute compounding periods: N × Years\n   - $nVal × ${result.time} = ${totalPeriods.toInt()} compounding terms',
          '4. Calculate Maturity Amount (A):\n   - $pStr × ${(1 + periodicRate).toStringAsFixed(6)}^${totalPeriods.toInt()} = $maturityStr',
          '5. Calculate Interest Earned:\n   - Maturity Amount ($maturityStr) − Principal ($pStr) = $interestStr',
        ];
        break;

      case 'EMI':
        title = 'Equated Monthly Installment (EMI)';
        formulas = [
          'EMI = [P × r × (1 + r)^n] / [(1 + r)^n − 1]',
          'Total Interest = (EMI × n) − P',
          'Total Payment = EMI × n',
          'P = Loan Amount, r = Monthly Rate (R / 12 / 100), n = Tenure in Months',
        ];

        final double months = result.timeUnit == 'Years' ? result.time * 12 : result.time;
        final double r = result.interestRate / (12 * 100);

        steps = [
          '1. Convert tenure to months (n):\n   - ${result.time} ${result.timeUnit} = ${months.toInt()} months',
          '2. Compute monthly interest rate (r):\n   - ${result.interestRate}% / 12 / 100 = ${r.toStringAsFixed(6)}',
          '3. Compute EMI:\n   - EMI = [$pStr × ${r.toStringAsFixed(6)} × ${(1 + r).toStringAsFixed(6)}^${months.toInt()}] / [${(1 + r).toStringAsFixed(6)}^${months.toInt()} − 1] = $emiStr',
          '4. Compute Total Payment:\n   - EMI ($emiStr) × ${months.toInt()} months = $totalStr',
          '5. Compute Total Interest:\n   - Total Payment ($totalStr) − Loan Amount ($pStr) = $interestStr',
        ];
        break;

      case 'Fixed Deposit':
        title = 'Fixed Deposit (FD)';
        formulas = [
          'Maturity Amount (A) = P × (1 + R / 400)^(4 × T)',
          'Interest Earned = A − P',
          'Compounded Quarterly (Standard Indian Bank Rule)',
        ];
        final rFactor = result.interestRate / 400;
        final totalTerms = 4 * result.time;

        steps = [
          '1. Set quarterly compounding: N = 4 quarters per year',
          '2. Compute quarterly interest factor: 1 + (R / 400)\n   - 1 + (${result.interestRate} / 400) = ${(1 + rFactor).toStringAsFixed(6)}',
          '3. Compute compounding terms: 4 × T\n   - 4 × ${result.time} years = ${totalTerms.toInt()} compounding terms',
          '4. Calculate Maturity Amount (A):\n   - $pStr × ${(1 + rFactor).toStringAsFixed(6)}^${totalTerms.toInt()} = $maturityStr',
          '5. Calculate Interest Earned:\n   - Maturity Amount ($maturityStr) − Principal ($pStr) = $interestStr',
        ];
        break;

      case 'Recurring Deposit':
        title = 'Recurring Deposit (RD)';
        formulas = [
          'Maturity Amount (M) = Monthly Installment × [(1 + i)^n − 1] / [1 − (1 + i)^(-1/3)]',
          'where i = R / 400 (quarterly rate), n = quarters (months / 3)',
          'Total Deposit = Monthly Installment × Months',
          'Interest Earned = M − Total Deposit',
        ];

        final double quarterlyRate = result.interestRate / 400;
        final double quarters = result.time / 3;
        final monthlyInst = result.totalAmount - result.interestAmount; // totalAmount = maturity, interestAmount = interest
        final totalDep = result.principal; // total principal deposited
        final singleInst = totalDep / result.time;

        steps = [
          '1. Monthly Saving: ${InterestFormatter.formatIndianCurrency(singleInst)} per month for ${result.time.toInt()} months',
          '2. Total Principal Deposited: ${InterestFormatter.formatIndianCurrency(singleInst)} × ${result.time.toInt()} = $pStr',
          '3. Compute quarterly rate (i) & quarters (n):\n   - i = ${result.interestRate}% / 400 = ${quarterlyRate.toStringAsFixed(6)}\n   - n = ${result.time.toInt()} months / 3 = ${quarters.toStringAsFixed(2)} quarters',
          '4. Calculate Maturity Value (M) compounding quarterly:\n   - Maturity = ${InterestFormatter.formatIndianCurrency(singleInst)} × [(1 + i)^n − 1] / [1 − (1 + i)^(-1/3)] = $maturityStr',
          '5. Calculate Interest Earned:\n   - Maturity Amount ($maturityStr) − Total Deposit ($pStr) = $interestStr',
        ];
        break;

      case 'Daily Interest':
        title = 'Daily Interest Calculator';
        formulas = [
          'Daily Interest Rate = Principal × (Rate % / 100) / 365',
          'Total Interest = Daily Interest × Days',
          'Final Amount = Principal + Total Interest',
        ];
        final dailyRateVal = result.principal * (result.interestRate / 100) / 365;

        steps = [
          '1. Calculate Daily Interest rate:\n   - $pStr × (${result.interestRate}% / 100) / 365 = ${InterestFormatter.formatIndianCurrency(dailyRateVal)} per day',
          '2. Calculate Total Interest for ${result.time.toInt()} days:\n   - ${InterestFormatter.formatIndianCurrency(dailyRateVal)} × ${result.time.toInt()} days = $interestStr',
          '3. Calculate Final Amount: Principal + Total Interest\n   - $pStr + $interestStr = $totalStr',
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
          
          // Formula Header Title
          Text(
            'Type: $title',
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
          
          // Steps Section
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
