import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gst_result_model.dart';
import '../services/gst_calculator_service.dart';
import '../utils/gst_validation.dart';

/// Riverpod provider for GstProvider.
final gstProvider = ChangeNotifierProvider<GstProvider>((ref) {
  return GstProvider();
});

class GstProvider extends ChangeNotifier {
  final GstCalculatorService _calculatorService = GstCalculatorService();
  
  final TextEditingController amountController = TextEditingController();
  
  double _selectedGstPercentage = 18.0; // Default GST rate
  int _selectedTypeIndex = 0; // 0: Exclusive, 1: Inclusive, 2: CGST+SGST, 3: IGST
  
  GstResultModel? _calculationResult;
  final List<GstResultModel> _history = [];
  
  String? _validationError;
  bool _isLoading = false;

  // Getters
  double get selectedGstPercentage => _selectedGstPercentage;
  int get selectedTypeIndex => _selectedTypeIndex;
  GstResultModel? get calculationResult => _calculationResult;
  List<GstResultModel> get history => _history;
  String? get validationError => _validationError;
  bool get isLoading => _isLoading;

  /// Update the selected GST percentage.
  void setGstPercentage(double percentage) {
    if (_selectedGstPercentage != percentage) {
      _selectedGstPercentage = percentage;
      notifyListeners();
    }
  }

  /// Update the selected GST type tab index.
  void setSelectedTypeIndex(int index) {
    if (_selectedTypeIndex != index) {
      _selectedTypeIndex = index;
      _validationError = null;
      _calculationResult = null; // Clear previous result to prompt fresh calculation
      notifyListeners();
    }
  }

  /// Perform validation and calculation with a premium loading delay.
  Future<void> calculate() async {
    final amountText = amountController.text;
    final validationResult = GstValidation.validateAmount(amountText);
    
    if (validationResult != null) {
      _validationError = validationResult;
      _calculationResult = null;
      notifyListeners();
      return;
    }

    _validationError = null;
    _isLoading = true;
    _calculationResult = null;
    notifyListeners();

    // Premium micro-animation delay
    await Future.delayed(const Duration(milliseconds: 600));

    final amount = double.parse(amountText.trim());
    GstResultModel result;

    switch (_selectedTypeIndex) {
      case 0:
        result = _calculatorService.calculateGSTExclusive(amount, _selectedGstPercentage);
        break;
      case 1:
        result = _calculatorService.calculateGSTInclusive(amount, _selectedGstPercentage);
        break;
      case 2:
        result = _calculatorService.calculateCGSTSGST(amount, _selectedGstPercentage);
        break;
      case 3:
        result = _calculatorService.calculateIGST(amount, _selectedGstPercentage);
        break;
      default:
        result = _calculatorService.calculateGSTExclusive(amount, _selectedGstPercentage);
    }

    _calculationResult = result;
    _history.insert(0, result); // Add to beginning of history list (newest first)
    _isLoading = false;
    notifyListeners();
  }

  /// Loads a previous calculation back into the active state.
  void loadHistoryItem(GstResultModel item) {
    int tabIndex = 0;
    if (item.calculationType == 'Exclusive') {
      tabIndex = 0;
    } else if (item.calculationType == 'Inclusive') {
      tabIndex = 1;
    } else if (item.calculationType == 'CGST + SGST') {
      tabIndex = 2;
    } else if (item.calculationType == 'IGST') {
      tabIndex = 3;
    }

    _selectedTypeIndex = tabIndex;
    _selectedGstPercentage = item.gstPercentage;

    if (tabIndex == 1) {
      amountController.text = item.finalAmount.toStringAsFixed(2);
    } else {
      amountController.text = item.originalAmount.toStringAsFixed(2);
    }

    _calculationResult = item;
    _validationError = null;
    notifyListeners();
  }

  /// Resets input fields and calculations.
  void reset() {
    amountController.clear();
    _selectedGstPercentage = 18.0;
    _calculationResult = null;
    _validationError = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Clears the calculation history.
  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  /// Removes a single item from the history.
  void deleteHistoryItem(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }
}
