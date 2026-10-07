import '../models/gst_result_model.dart';

class GstCalculatorService {
  /// Calculates GST Exclusive (Add GST)
  /// Formula:
  /// GST Amount = Amount × (GST % / 100)
  /// Final Amount = Amount + GST Amount
  GstResultModel calculateGSTExclusive(double amount, double gstPercent) {
    final gstAmount = amount * (gstPercent / 100);
    final finalAmount = amount + gstAmount;

    return GstResultModel(
      originalAmount: amount,
      gstPercentage: gstPercent,
      gstAmount: gstAmount,
      cgstAmount: 0.0,
      sgstAmount: 0.0,
      igstAmount: 0.0,
      finalAmount: finalAmount,
      calculationType: 'Exclusive',
      createdAt: DateTime.now(),
    );
  }

  /// Calculates GST Inclusive (Remove GST)
  /// Formula:
  /// Original Amount = Total Amount / (1 + (GST % / 100))
  /// GST Amount = Total Amount − Original Amount
  GstResultModel calculateGSTInclusive(double totalAmount, double gstPercent) {
    final originalAmount = totalAmount / (1 + (gstPercent / 100));
    final gstAmount = totalAmount - originalAmount;

    return GstResultModel(
      originalAmount: originalAmount,
      gstPercentage: gstPercent,
      gstAmount: gstAmount,
      cgstAmount: 0.0,
      sgstAmount: 0.0,
      igstAmount: 0.0,
      finalAmount: totalAmount,
      calculationType: 'Inclusive',
      createdAt: DateTime.now(),
    );
  }

  /// Calculates Intra-State GST (CGST + SGST)
  /// Formula:
  /// CGST = (Amount × (GST % / 100)) / 2
  /// SGST = (Amount × (GST % / 100)) / 2
  /// Total GST = CGST + SGST
  /// Final Amount = Amount + Total GST
  GstResultModel calculateCGSTSGST(double amount, double gstPercent) {
    final totalGstAmount = amount * (gstPercent / 100);
    final cgstAmount = totalGstAmount / 2;
    final sgstAmount = totalGstAmount / 2;
    final finalAmount = amount + totalGstAmount;

    return GstResultModel(
      originalAmount: amount,
      gstPercentage: gstPercent,
      gstAmount: totalGstAmount,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      igstAmount: 0.0,
      finalAmount: finalAmount,
      calculationType: 'CGST + SGST',
      createdAt: DateTime.now(),
    );
  }

  /// Calculates Inter-State GST (IGST)
  /// Formula:
  /// IGST = Amount × (GST % / 100)
  /// Final Amount = Amount + IGST
  GstResultModel calculateIGST(double amount, double gstPercent) {
    final igstAmount = amount * (gstPercent / 100);
    final finalAmount = amount + igstAmount;

    return GstResultModel(
      originalAmount: amount,
      gstPercentage: gstPercent,
      gstAmount: igstAmount,
      cgstAmount: 0.0,
      sgstAmount: 0.0,
      igstAmount: igstAmount,
      finalAmount: finalAmount,
      calculationType: 'IGST',
      createdAt: DateTime.now(),
    );
  }
}
