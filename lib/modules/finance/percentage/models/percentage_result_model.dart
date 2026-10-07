class PercentageResultModel {
  final Map<String, double> inputValues;
  final double result;
  final double percentage;
  final String calculationType;
  final String formula;
  final DateTime createdAt;

  const PercentageResultModel({
    required this.inputValues,
    required this.result,
    required this.percentage,
    required this.calculationType,
    required this.formula,
    required this.createdAt,
  });

  PercentageResultModel copyWith({
    Map<String, double>? inputValues,
    double? result,
    double? percentage,
    String? calculationType,
    String? formula,
    DateTime? createdAt,
  }) {
    return PercentageResultModel(
      inputValues: inputValues ?? this.inputValues,
      result: result ?? this.result,
      percentage: percentage ?? this.percentage,
      calculationType: calculationType ?? this.calculationType,
      formula: formula ?? this.formula,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inputValues': inputValues,
      'result': result,
      'percentage': percentage,
      'calculationType': calculationType,
      'formula': formula,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PercentageResultModel.fromMap(Map<String, dynamic> map) {
    // Safely parse map of input values
    final rawInputs = map['inputValues'] as Map;
    final Map<String, double> inputs = {};
    rawInputs.forEach((key, val) {
      inputs[key.toString()] = (val as num).toDouble();
    });

    return PercentageResultModel(
      inputValues: inputs,
      result: (map['result'] as num).toDouble(),
      percentage: (map['percentage'] as num).toDouble(),
      calculationType: map['calculationType'] as String,
      formula: map['formula'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
