class GstResultModel {
  final double originalAmount;
  final double gstPercentage;
  final double gstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double finalAmount;
  final String calculationType; // "Exclusive" | "Inclusive" | "CGST/SGST" | "IGST"
  final DateTime createdAt;

  const GstResultModel({
    required this.originalAmount,
    required this.gstPercentage,
    required this.gstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.finalAmount,
    required this.calculationType,
    required this.createdAt,
  });

  /// Factory method to create a copy of the model with overrides.
  GstResultModel copyWith({
    double? originalAmount,
    double? gstPercentage,
    double? gstAmount,
    double? cgstAmount,
    double? sgstAmount,
    double? igstAmount,
    double? finalAmount,
    String? calculationType,
    DateTime? createdAt,
  }) {
    return GstResultModel(
      originalAmount: originalAmount ?? this.originalAmount,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      gstAmount: gstAmount ?? this.gstAmount,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      igstAmount: igstAmount ?? this.igstAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      calculationType: calculationType ?? this.calculationType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert model to a Map (useful for future persistence or logging).
  Map<String, dynamic> toMap() {
    return {
      'originalAmount': originalAmount,
      'gstPercentage': gstPercentage,
      'gstAmount': gstAmount,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'finalAmount': finalAmount,
      'calculationType': calculationType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create model from a Map.
  factory GstResultModel.fromMap(Map<String, dynamic> map) {
    return GstResultModel(
      originalAmount: (map['originalAmount'] as num).toDouble(),
      gstPercentage: (map['gstPercentage'] as num).toDouble(),
      gstAmount: (map['gstAmount'] as num).toDouble(),
      cgstAmount: (map['cgstAmount'] as num).toDouble(),
      sgstAmount: (map['sgstAmount'] as num).toDouble(),
      igstAmount: (map['igstAmount'] as num).toDouble(),
      finalAmount: (map['finalAmount'] as num).toDouble(),
      calculationType: map['calculationType'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
