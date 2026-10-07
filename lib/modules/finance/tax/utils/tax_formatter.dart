class TaxFormatter {
  /// Formats a double amount into Indian currency format (e.g. ₹12,34,567.89).
  static String formatIndianCurrency(double amount) {
    if (amount.isNaN || amount.isInfinite) return '₹0.00';

    final isNegative = amount < 0;
    final absAmount = amount.abs();
    
    final fixedStr = absAmount.toStringAsFixed(2);
    final parts = fixedStr.split('.');
    String integerPart = parts[0];
    final decimalPart = parts[1];

    if (integerPart.length <= 3) {
      return '${isNegative ? '-' : ''}₹$integerPart.$decimalPart';
    }

    final lastThree = integerPart.substring(integerPart.length - 3);
    final remaining = integerPart.substring(0, integerPart.length - 3);

    String grouped = '';
    int count = 0;
    for (int i = remaining.length - 1; i >= 0; i--) {
      grouped = remaining[i] + grouped;
      count++;
      if (count == 2 && i > 0) {
        grouped = ',$grouped';
        count = 0;
      }
    }

    return '${isNegative ? '-' : ''}₹$grouped,$lastThree.$decimalPart';
  }

  /// Formats a percentage value.
  static String formatPercentage(double value) {
    if (value.isNaN || value.isInfinite) return '0%';
    final isInt = value == value.toInt();
    final str = isInt ? value.toInt().toString() : value.toStringAsFixed(2);
    return '$str%';
  }

  /// Formats date-time.
  static String formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month - 1];
    final year = dateTime.year;

    int hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour > 12) {
      hour -= 12;
    } else if (hour == 0) {
      hour = 12;
    }

    return '$day $month $year, $hour:$minute $period';
  }
}
