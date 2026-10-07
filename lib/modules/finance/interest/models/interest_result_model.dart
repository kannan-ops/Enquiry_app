class InterestResultModel {
  final double principal;
  final double interestRate;
  final double time;
  final String timeUnit; // "Days" | "Months" | "Years"
  final double interestAmount;
  final double totalAmount;
  final double emi; // Monthly payment (only for EMI, 0.0 otherwise)
  final double maturityAmount; // For FD, RD, and Compound Interest, 0.0 otherwise
  final String calculationType; // "Simple Interest" | "Compound Interest" | "EMI" | "Fixed Deposit" | "Recurring Deposit" | "Daily Interest"
  final String? compoundFrequency; // "Yearly" | "Half-Yearly" | "Quarterly" | "Monthly"
  final DateTime createdAt;

  const InterestResultModel({
    required this.principal,
    required this.interestRate,
    required this.time,
    required this.timeUnit,
    required this.interestAmount,
    required this.totalAmount,
    required this.emi,
    required this.maturityAmount,
    required this.calculationType,
    this.compoundFrequency,
    required this.createdAt,
  });

  /// Factory method to duplicate with edits.
  InterestResultModel copyWith({
    double? principal,
    double? interestRate,
    double? time,
    String? timeUnit,
    double? interestAmount,
    double? totalAmount,
    double? emi,
    double? maturityAmount,
    String? calculationType,
    String? compoundFrequency,
    DateTime? createdAt,
  }) {
    return InterestResultModel(
      principal: principal ?? this.principal,
      interestRate: interestRate ?? this.interestRate,
      time: time ?? this.time,
      timeUnit: timeUnit ?? this.timeUnit,
      interestAmount: interestAmount ?? this.interestAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      emi: emi ?? this.emi,
      maturityAmount: maturityAmount ?? this.maturityAmount,
      calculationType: calculationType ?? this.calculationType,
      compoundFrequency: compoundFrequency ?? this.compoundFrequency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert model to a Map.
  Map<String, dynamic> toMap() {
    return {
      'principal': principal,
      'interestRate': interestRate,
      'time': time,
      'timeUnit': timeUnit,
      'interestAmount': interestAmount,
      'totalAmount': totalAmount,
      'emi': emi,
      'maturityAmount': maturityAmount,
      'calculationType': calculationType,
      'compoundFrequency': compoundFrequency,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create model from a Map.
  factory InterestResultModel.fromMap(Map<String, dynamic> map) {
    return InterestResultModel(
      principal: (map['principal'] as num).toDouble(),
      interestRate: (map['interestRate'] as num).toDouble(),
      time: (map['time'] as num).toDouble(),
      timeUnit: map['timeUnit'] as String,
      interestAmount: (map['interestAmount'] as num).toDouble(),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      emi: (map['emi'] as num).toDouble(),
      maturityAmount: (map['maturityAmount'] as num).toDouble(),
      calculationType: map['calculationType'] as String,
      compoundFrequency: map['compoundFrequency'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
