class GstValidation {
  /// Validates the amount input. Returns null if valid, otherwise an error message string.
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount cannot be empty';
    }

    final trimmed = value.trim();
    final number = double.tryParse(trimmed);
    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < 0) {
      return 'Amount cannot be negative';
    }

    if (number == 0) {
      return 'Amount must be greater than zero';
    }

    // Check if the string has a decimal and more than 2 decimal places (optional validation)
    if (trimmed.contains('.')) {
      final decimalPart = trimmed.split('.')[1];
      if (decimalPart.length > 4) {
        return 'Max 4 decimal places allowed';
      }
    }

    return null;
  }

  /// Validates the GST percentage.
  static String? validateGstPercentage(double? percentage) {
    if (percentage == null) {
      return 'Please select a GST rate';
    }
    if (percentage < 0) {
      return 'GST percentage cannot be negative';
    }
    return null;
  }
}
