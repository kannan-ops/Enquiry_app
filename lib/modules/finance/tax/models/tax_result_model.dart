class TaxResultModel {
  final double originalAmount;
  final double taxPercentage;
  final double taxAmount;
  final double finalAmount;
  final DateTime createdAt;

  const TaxResultModel({
    required this.originalAmount,
    required this.taxPercentage,
    required this.taxAmount,
    required this.finalAmount,
    required this.createdAt,
  });

  TaxResultModel copyWith({
    double? originalAmount,
    double? taxPercentage,
    double? taxAmount,
    double? finalAmount,
    DateTime? createdAt,
  }) {
    return TaxResultModel(
      originalAmount: originalAmount ?? this.originalAmount,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      taxAmount: taxAmount ?? this.taxAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'originalAmount': originalAmount,
      'taxPercentage': taxPercentage,
      'taxAmount': taxAmount,
      'finalAmount': finalAmount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaxResultModel.fromMap(Map<String, dynamic> map) {
    return TaxResultModel(
      originalAmount: (map['originalAmount'] as num).toDouble(),
      taxPercentage: (map['taxPercentage'] as num).toDouble(),
      taxAmount: (map['taxAmount'] as num).toDouble(),
      finalAmount: (map['finalAmount'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
