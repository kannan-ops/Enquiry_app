class TaxValidation {
  /// Validates standard amount input.
  static String? validateAmount(String? value, {required String fieldName, bool allowZero = true}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }

    final trimmed = value.trim();
    final number = double.tryParse(trimmed);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < 0) {
      return '$fieldName cannot be negative';
    }

    if (!allowZero && number == 0) {
      return '$fieldName must be greater than zero';
    }

    return null;
  }

  /// Validates standard tax rate percentage.
  static String? validatePercentage(String? value, {String fieldName = 'Tax Percentage'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName cannot be empty';
    }

    final trimmed = value.trim();
    final number = double.tryParse(trimmed);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < 0) {
      return '$fieldName cannot be negative';
    }

    if (number > 100) {
      return '$fieldName cannot exceed 100%';
    }

    return null;
  }
}
