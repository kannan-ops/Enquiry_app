import 'dart:math';
import '../models/interest_result_model.dart';

class InterestCalculatorService {
  /// Calculates Simple Interest.
  /// Formula:
  /// T = time adjusted to years
  /// SI = (P × R × T) / 100
  /// Total Amount = P + SI
  InterestResultModel calculateSimpleInterest(
    double principal,
    double rate,
    double time,
    String unit,
  ) {
    double tInYears = time;
    if (unit == 'Months') {
      tInYears = time / 12;
    } else if (unit == 'Days') {
      tInYears = time / 365;
    }

    final interestAmount = (principal * rate * tInYears) / 100;
    final totalAmount = principal + interestAmount;

    return InterestResultModel(
      principal: principal,
      interestRate: rate,
      time: time,
      timeUnit: unit,
      interestAmount: interestAmount,
      totalAmount: totalAmount,
      emi: 0.0,
      maturityAmount: 0.0,
      calculationType: 'Simple Interest',
      createdAt: DateTime.now(),
    );
  }

  /// Calculates Compound Interest.
  /// Formula:
  /// A = P × (1 + R/(N×100))^(N×T)
  /// Interest Earned = A - P
  InterestResultModel calculateCompoundInterest(
    double principal,
    double rate,
    double years,
    String frequency,
  ) {
    double n = 1;
    switch (frequency) {
      case 'Yearly':
        n = 1;
        break;
      case 'Half-Yearly':
        n = 2;
        break;
      case 'Quarterly':
        n = 4;
        break;
      case 'Monthly':
        n = 12;
        break;
    }

    // A = P * (1 + r/n)^(n*t)
    final r = rate / 100;
    final maturityAmount = principal * pow(1 + (r / n), n * years);
    final interestAmount = maturityAmount - principal;

    return InterestResultModel(
      principal: principal,
      interestRate: rate,
      time: years,
      timeUnit: 'Years',
      interestAmount: interestAmount,
      totalAmount: maturityAmount,
      emi: 0.0,
      maturityAmount: maturityAmount,
      calculationType: 'Compound Interest',
      compoundFrequency: frequency,
      createdAt: DateTime.now(),
    );
  }

  /// Calculates Equated Monthly Installment (EMI).
  /// Formula:
  /// E = P × r × (1 + r)^n / ((1 + r)^n - 1)
  /// where r is monthly rate, n is tenure in months.
  InterestResultModel calculateEMI(
    double principal,
    double rate,
    double tenure,
    String unit,
  ) {
    final double months = unit == 'Years' ? tenure * 12 : tenure;
    final double r = rate / (12 * 100); // monthly interest rate

    double emiVal = 0.0;
    if (months > 0) {
      if (r == 0) {
        emiVal = principal / months;
      } else {
        emiVal = principal * r * pow(1 + r, months) / (pow(1 + r, months) - 1);
      }
    }

    final totalPayment = emiVal * months;
    final totalInterest = totalPayment - principal;

    return InterestResultModel(
      principal: principal,
      interestRate: rate,
      time: tenure,
      timeUnit: unit,
      interestAmount: totalInterest,
      totalAmount: totalPayment,
      emi: emiVal,
      maturityAmount: 0.0,
      calculationType: 'EMI',
      createdAt: DateTime.now(),
    );
  }

  /// Calculates Fixed Deposit (FD) Maturity.
  /// Standard FD compounding is Quarterly.
  /// Formula:
  /// A = P × (1 + R/400)^(4×T)
  /// Interest Earned = A - P
  InterestResultModel calculateFD(double principal, double rate, double years) {
    const double n = 4.0; // quarterly compounding
    final double r = rate / 100;
    final maturityAmount = principal * pow(1 + (r / n), n * years);
    final interestAmount = maturityAmount - principal;

    return InterestResultModel(
      principal: principal,
      interestRate: rate,
      time: years,
      timeUnit: 'Years',
      interestAmount: interestAmount,
      totalAmount: maturityAmount,
      emi: 0.0,
      maturityAmount: maturityAmount,
      calculationType: 'Fixed Deposit',
      compoundFrequency: 'Quarterly',
      createdAt: DateTime.now(),
    );
  }

  /// Calculates Recurring Deposit (RD) Maturity.
  /// RD compounds Quarterly.
  /// Formula:
  /// M = P × ((1 + i)^n - 1) / (1 - (1 + i)^(-1/3))
  /// where i = R / 400, n = months / 3.
  InterestResultModel calculateRD(
    double monthlyDeposit,
    double rate,
    double months,
  ) {
    if (rate == 0) {
      final totalDeposit = monthlyDeposit * months;
      return InterestResultModel(
        principal: totalDeposit,
        interestRate: rate,
        time: months,
        timeUnit: 'Months',
        interestAmount: 0.0,
        totalAmount: totalDeposit,
        emi: 0.0,
        maturityAmount: totalDeposit,
        calculationType: 'Recurring Deposit',
        compoundFrequency: 'Quarterly',
        createdAt: DateTime.now(),
      );
    }

    final double i = rate / 400; // quarterly rate
    final double n = months / 3; // quarters
    
    final maturityAmount = monthlyDeposit * (pow(1 + i, n) - 1) / (1 - pow(1 + i, -1.0 / 3.0));
    final totalDeposit = monthlyDeposit * months;
    final interestAmount = maturityAmount - totalDeposit;

    return InterestResultModel(
      principal: totalDeposit, // total principal deposited
      interestRate: rate,
      time: months,
      timeUnit: 'Months',
      interestAmount: interestAmount,
      totalAmount: maturityAmount,
      emi: 0.0,
      maturityAmount: maturityAmount,
      calculationType: 'Recurring Deposit',
      compoundFrequency: 'Quarterly',
      createdAt: DateTime.now(),
    );
  }

  /// Calculates Daily Interest.
  /// Formula:
  /// Daily Interest = P × (R / 100) / 365
  /// Total Interest = Daily Interest × Days
  /// Final Amount = P + Total Interest
  InterestResultModel calculateDailyInterest(
    double principal,
    double rate,
    double days,
  ) {
    final dailyInterest = principal * (rate / 100) / 365;
    final totalInterest = dailyInterest * days;
    final finalAmount = principal + totalInterest;

    return InterestResultModel(
      principal: principal,
      interestRate: rate,
      time: days,
      timeUnit: 'Days',
      interestAmount: totalInterest,
      totalAmount: finalAmount,
      emi: dailyInterest, // misuse emi field slightly to store daily interest rate for display, or we can compute in result card
      maturityAmount: 0.0,
      calculationType: 'Daily Interest',
      createdAt: DateTime.now(),
    );
  }
}
