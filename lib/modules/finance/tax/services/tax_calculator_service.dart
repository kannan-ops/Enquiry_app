import '../models/tax_result_model.dart';
import '../utils/tax_validation.dart';

class TaxCalculatorService {
  /// Calculate custom tax.
  /// Tax Amount = Amount × Tax Percentage ÷ 100
  /// Final Amount = Amount + Tax Amount
  TaxResultModel calculateTax(double amount, double taxPercentage) {
    final taxAmount = amount * taxPercentage / 100;
    final finalAmount = amount + taxAmount;
    
    return TaxResultModel(
      originalAmount: amount,
      taxPercentage: taxPercentage,
      taxAmount: taxAmount,
      finalAmount: finalAmount,
      createdAt: DateTime.now(),
    );
  }

  /// Validates both fields and returns an error message map.
  Map<String, String?> validateTax(String amountStr, String percentageStr) {
    final Map<String, String?> errors = {};
    
    final amtError = TaxValidation.validateAmount(amountStr, fieldName: 'Amount', allowZero: false);
    final pctError = TaxValidation.validatePercentage(percentageStr, fieldName: 'Tax Percentage');
    
    if (amtError != null) errors['amount'] = amtError;
    if (pctError != null) errors['percentage'] = pctError;
    
    return errors;
  }

  /// Resets calculations and returns standard initial states.
  TaxResultModel? resetCalculation() {
    return null;
  }
}
