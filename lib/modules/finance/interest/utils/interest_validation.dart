class InterestValidation {
  /// Validates the principal or deposit amount.
  static String? validateAmount(String? value, {String fieldName = 'Amount'}) {
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

    if (number == 0) {
      return '$fieldName must be greater than zero';
    }

    return null;
  }

  /// Validates the interest rate.
  static String? validateRate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Interest rate cannot be empty';
    }

    final trimmed = value.trim();
    final number = double.tryParse(trimmed);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < 0) {
      return 'Interest rate cannot be negative';
    }

    if (number == 0) {
      return 'Interest rate must be greater than zero';
    }

    if (number > 100) {
      return 'Rate cannot exceed 100%';
    }

    return null;
  }

  /// Validates time/tenure.
  static String? validateTime(String? value, {String fieldName = 'Tenure'}) {
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

    if (number == 0) {
      return '$fieldName must be greater than zero';
    }

    return null;
  }
}
