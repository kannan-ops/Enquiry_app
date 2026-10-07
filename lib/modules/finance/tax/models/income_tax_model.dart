class IncomeTaxModel {
  final double grossIncome;
  final double taxableIncome;
  final double basicTax;
  final double cess;
  final double rebate;
  final double totalTaxPayable;
  final double effectiveTaxRate;
  final double netIncome;
  final String regime;
  final String ageGroup;
  final Map<String, double> deductions;
  final DateTime createdAt;

  const IncomeTaxModel({
    required this.grossIncome,
    required this.taxableIncome,
    required this.basicTax,
    required this.cess,
    required this.rebate,
    required this.totalTaxPayable,
    required this.effectiveTaxRate,
    required this.netIncome,
    required this.regime,
    required this.ageGroup,
    required this.deductions,
    required this.createdAt,
  });

  IncomeTaxModel copyWith({
    double? grossIncome,
    double? taxableIncome,
    double? basicTax,
    double? cess,
    double? rebate,
    double? totalTaxPayable,
    double? effectiveTaxRate,
    double? netIncome,
    String? regime,
    String? ageGroup,
    Map<String, double>? deductions,
    DateTime? createdAt,
  }) {
    return IncomeTaxModel(
      grossIncome: grossIncome ?? this.grossIncome,
      taxableIncome: taxableIncome ?? this.taxableIncome,
      basicTax: basicTax ?? this.basicTax,
      cess: cess ?? this.cess,
      rebate: rebate ?? this.rebate,
      totalTaxPayable: totalTaxPayable ?? this.totalTaxPayable,
      effectiveTaxRate: effectiveTaxRate ?? this.effectiveTaxRate,
      netIncome: netIncome ?? this.netIncome,
      regime: regime ?? this.regime,
      ageGroup: ageGroup ?? this.ageGroup,
      deductions: deductions ?? this.deductions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'grossIncome': grossIncome,
      'taxableIncome': taxableIncome,
      'basicTax': basicTax,
      'cess': cess,
      'rebate': rebate,
      'totalTaxPayable': totalTaxPayable,
      'effectiveTaxRate': effectiveTaxRate,
      'netIncome': netIncome,
      'regime': regime,
      'ageGroup': ageGroup,
      'deductions': deductions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory IncomeTaxModel.fromMap(Map<String, dynamic> map) {
    final rawDeductions = map['deductions'] as Map;
    final Map<String, double> deds = {};
    rawDeductions.forEach((key, val) {
      deds[key.toString()] = (val as num).toDouble();
    });

    return IncomeTaxModel(
      grossIncome: (map['grossIncome'] as num).toDouble(),
      taxableIncome: (map['taxableIncome'] as num).toDouble(),
      basicTax: (map['basicTax'] as num).toDouble(),
      cess: (map['cess'] as num).toDouble(),
      rebate: (map['rebate'] as num).toDouble(),
      totalTaxPayable: (map['totalTaxPayable'] as num).toDouble(),
      effectiveTaxRate: (map['effectiveTaxRate'] as num).toDouble(),
      netIncome: (map['netIncome'] as num).toDouble(),
      regime: map['regime'] as String,
      ageGroup: map['ageGroup'] as String,
      deductions: deds,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
