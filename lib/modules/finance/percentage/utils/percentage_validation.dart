class PercentageValidation {
  /// Validates input number.
  static String? validateNumber(String? value, {required String fieldName, bool allowZero = true, bool allowNegative = false}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }

    final trimmed = value.trim();
    final number = double.tryParse(trimmed);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (!allowNegative && number < 0) {
      return '$fieldName cannot be negative';
    }

    if (!allowZero && number == 0) {
      return '$fieldName cannot be zero';
    }

    return null;
  }
}
