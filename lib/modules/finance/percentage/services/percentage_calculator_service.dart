import '../models/percentage_result_model.dart';

class PercentageCalculatorService {
  /// Calculate X% of a number.
  /// Result = Number × Percentage ÷ 100
  PercentageResultModel calculatePercentageOfNumber(double number, double percentage) {
    final result = number * percentage / 100;
    return PercentageResultModel(
      inputValues: {'Number': number, 'Percentage': percentage},
      result: result,
      percentage: percentage,
      calculationType: 'Percentage of Number',
      formula: 'Result = Number × Percentage ÷ 100',
      createdAt: DateTime.now(),
    );
  }

  /// Find what percentage one number is of another.
  /// Percentage = (Value ÷ Total Value) × 100
  PercentageResultModel calculateWhatPercentage(double value, double total) {
    final percentage = total == 0 ? 0.0 : (value / total) * 100;
    return PercentageResultModel(
      inputValues: {'Value': value, 'Total Value': total},
      result: value,
      percentage: percentage,
      calculationType: 'What Percentage?',
      formula: 'Percentage = (Value ÷ Total Value) × 100',
      createdAt: DateTime.now(),
    );
  }

  /// Percentage Increase
  /// Increase % = ((New − Old) ÷ Old) × 100
  PercentageResultModel calculatePercentageIncrease(double oldVal, double newVal) {
    final diff = newVal - oldVal;
    final percentage = oldVal == 0 ? 0.0 : (diff / oldVal) * 100;
    return PercentageResultModel(
      inputValues: {'Old Value': oldVal, 'New Value': newVal},
      result: diff,
      percentage: percentage,
      calculationType: 'Percentage Increase',
      formula: 'Increase % = ((New − Old) ÷ Old) × 100',
      createdAt: DateTime.now(),
    );
  }

  /// Percentage Decrease
  /// Decrease % = ((Old − New) ÷ Old) × 100
  PercentageResultModel calculatePercentageDecrease(double oldVal, double newVal) {
    final diff = oldVal - newVal;
    final percentage = oldVal == 0 ? 0.0 : (diff / oldVal) * 100;
    return PercentageResultModel(
      inputValues: {'Old Value': oldVal, 'New Value': newVal},
      result: diff,
      percentage: percentage,
      calculationType: 'Percentage Decrease',
      formula: 'Decrease % = ((Old − New) ÷ Old) × 100',
      createdAt: DateTime.now(),
    );
  }

  /// Percentage Difference
  /// Difference % = (|Value 1 − Value 2| ÷ ((Value 1 + Value 2) ÷ 2)) × 100
  PercentageResultModel calculatePercentageDifference(double val1, double val2) {
    final diff = (val1 - val2).abs();
    final average = (val1 + val2) / 2;
    final percentage = average == 0 ? 0.0 : (diff / average) * 100;
    return PercentageResultModel(
      inputValues: {'Value 1': val1, 'Value 2': val2},
      result: diff,
      percentage: percentage,
      calculationType: 'Percentage Difference',
      formula: 'Difference % = (|Value 1 − Value 2| ÷ Average) × 100',
      createdAt: DateTime.now(),
    );
  }

  /// Profit Percentage
  /// Profit % = ((SP − CP) ÷ CP) × 100
  PercentageResultModel calculateProfitPercentage(double cp, double sp) {
    final profit = sp - cp;
    final percentage = cp == 0 ? 0.0 : (profit / cp) * 100;
    return PercentageResultModel(
      inputValues: {'Cost Price (CP)': cp, 'Selling Price (SP)': sp},
      result: profit,
      percentage: percentage,
      calculationType: 'Profit Percentage',
      formula: 'Profit % = ((SP − CP) ÷ CP) × 100',
      createdAt: DateTime.now(),
    );
  }

  /// Loss Percentage
  /// Loss % = ((CP − SP) ÷ CP) × 100
  PercentageResultModel calculateLossPercentage(double cp, double sp) {
    final loss = cp - sp;
    final percentage = cp == 0 ? 0.0 : (loss / cp) * 100;
    return PercentageResultModel(
      inputValues: {'Cost Price (CP)': cp, 'Selling Price (SP)': sp},
      result: loss,
      percentage: percentage,
      calculationType: 'Loss Percentage',
      formula: 'Loss % = ((CP − SP) ÷ CP) × 100',
      createdAt: DateTime.now(),
    );
  }

  /// Discount Calculator
  /// Discount Amount = Price × Discount % ÷ 100
  /// Final Price = Price − Discount Amount
  PercentageResultModel calculateDiscount(double price, double discountPercent) {
    final discountAmount = price * discountPercent / 100;
    final finalPrice = price - discountAmount;
    return PercentageResultModel(
      inputValues: {'Original Price': price, 'Discount (%)': discountPercent},
      result: finalPrice,
      percentage: discountAmount, // using percentage field to store discount amount for display
      calculationType: 'Discount Calculator',
      formula: 'Discount Amount = Price × Discount % ÷ 100',
      createdAt: DateTime.now(),
    );
  }

  /// Markup Calculator
  /// Markup Amount = Cost × Markup % ÷ 100
  /// Selling Price = Cost + Markup Amount
  PercentageResultModel calculateMarkup(double cost, double markupPercent) {
    final markupAmount = cost * markupPercent / 100;
    final sellingPrice = cost + markupAmount;
    return PercentageResultModel(
      inputValues: {'Cost Price': cost, 'Markup (%)': markupPercent},
      result: sellingPrice,
      percentage: markupAmount, // using percentage field to store markup amount
      calculationType: 'Markup Calculator',
      formula: 'Selling Price = Cost + Markup Amount',
      createdAt: DateTime.now(),
    );
  }

  /// Margin Calculator
  /// Margin % = ((SP − CP) ÷ SP) × 100
  PercentageResultModel calculateMargin(double cost, double sellingPrice) {
    final profit = sellingPrice - cost;
    final percentage = sellingPrice == 0 ? 0.0 : (profit / sellingPrice) * 100;
    return PercentageResultModel(
      inputValues: {'Cost Price': cost, 'Selling Price': sellingPrice},
      result: profit,
      percentage: percentage,
      calculationType: 'Margin Calculator',
      formula: 'Margin % = ((SP − CP) ÷ SP) × 100',
      createdAt: DateTime.now(),
    );
  }

  /// Percentage Change
  /// Change % = ((New − Old) ÷ Old) × 100
  PercentageResultModel calculatePercentageChange(double oldVal, double newVal) {
    final change = newVal - oldVal;
    final percentage = oldVal == 0 ? 0.0 : (change / oldVal) * 100;
    return PercentageResultModel(
      inputValues: {'Old Value': oldVal, 'New Value': newVal},
      result: change,
      percentage: percentage,
      calculationType: 'Percentage Change',
      formula: 'Change % = ((New − Old) ÷ Old) × 100',
      createdAt: DateTime.now(),
    );
  }

  /// Commission Calculator
  /// Commission Amount = Sale × Commission % ÷ 100
  /// Net Amount = Sale − Commission Amount
  PercentageResultModel calculateCommission(double amount, double commissionPercent) {
    final commissionAmount = amount * commissionPercent / 100;
    final netAmount = amount - commissionAmount;
    return PercentageResultModel(
      inputValues: {'Sale Amount': amount, 'Commission (%)': commissionPercent},
      result: netAmount,
      percentage: commissionAmount, // using percentage field to store commission amount
      calculationType: 'Commission Calculator',
      formula: 'Commission Amount = Sale × Commission % ÷ 100',
      createdAt: DateTime.now(),
    );
  }
}
