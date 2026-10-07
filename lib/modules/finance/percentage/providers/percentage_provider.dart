import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/percentage_result_model.dart';
import '../services/percentage_calculator_service.dart';
import '../utils/percentage_validation.dart';
import '../constants/percentage_constants.dart';

final percentageProvider = ChangeNotifierProvider<PercentageProvider>((ref) {
  return PercentageProvider();
});

class PercentageProvider extends ChangeNotifier {
  final PercentageCalculatorService _calculatorService = PercentageCalculatorService();

  // Controllers
  final TextEditingController input1Controller = TextEditingController();
  final TextEditingController input2Controller = TextEditingController();

  // Active Tab
  int _selectedTabIndex = 0; // 0 to 11

  // Calculation State
  PercentageResultModel? _calculationResult;
  final List<PercentageResultModel> _history = [];
  final Set<String> _favorites = {};

  // UI States
  bool _isLoading = false;
  String? _input1Error;
  String? _input2Error;

  PercentageProvider() {
    _loadFavorites();
  }

  // Getters
  int get selectedTabIndex => _selectedTabIndex;
  PercentageResultModel? get calculationResult => _calculationResult;
  List<PercentageResultModel> get history => _history;
  Set<String> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get input1Error => _input1Error;
  String? get input2Error => _input2Error;

  // Favorites System Persistence
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList('percentage_calculator_favorites');
      if (favList != null) {
        _favorites.addAll(favList);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> toggleFavorite(String calcName) async {
    if (_favorites.contains(calcName)) {
      _favorites.remove(calcName);
    } else {
      _favorites.add(calcName);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('percentage_calculator_favorites', _favorites.toList());
    } catch (_) {}
  }

  bool isFavorite(String calcName) => _favorites.contains(calcName);

  // Setters
  void setSelectedTabIndex(int index) {
    if (_selectedTabIndex != index && index >= 0 && index < percentageCalculatorsMeta.length) {
      _selectedTabIndex = index;
      _clearValidationErrors();
      _calculationResult = null;
      notifyListeners();
    }
  }

  void _clearValidationErrors() {
    _input1Error = null;
    _input2Error = null;
  }

  /// Reset form values and result
  void reset() {
    input1Controller.clear();
    input2Controller.clear();
    _calculationResult = null;
    _clearValidationErrors();
    _isLoading = false;
    notifyListeners();
  }

  /// Perform percentage calculation
  Future<void> calculate() async {
    _clearValidationErrors();
    final meta = percentageCalculatorsMeta[_selectedTabIndex];
    final label1 = meta['input1Label'] as String;
    final label2 = meta['input2Label'] as String;

    // Run basic validations (empty and negative checks)
    // Most percentage inputs cannot be negative, but let's allow negatives for Value 1 & Value 2 in Increase/Decrease/Change
    final bool allowNegative = _selectedTabIndex == 2 || _selectedTabIndex == 3 || _selectedTabIndex == 4 || _selectedTabIndex == 10;
    
    // Most calculators don't want 0 in input 1 or 2 if division by zero occurs
    // We validate non-zero division bounds
    bool input1AllowZero = true;
    bool input2AllowZero = true;

    if (_selectedTabIndex == 1) input2AllowZero = false; // Total Value cannot be zero (What Percentage?)
    if (_selectedTabIndex == 2 || _selectedTabIndex == 3 || _selectedTabIndex == 10) {
      input1AllowZero = false; // Old Value cannot be zero (Percentage Increase/Decrease/Change)
    }
    if (_selectedTabIndex == 5 || _selectedTabIndex == 6) {
      input1AllowZero = false; // Cost Price cannot be zero (Profit/Loss Percentage)
    }
    if (_selectedTabIndex == 9) {
      input2AllowZero = false; // Selling Price cannot be zero (Margin Calculator)
    }

    final val1 = PercentageValidation.validateNumber(
      input1Controller.text,
      fieldName: label1,
      allowZero: input1AllowZero,
      allowNegative: allowNegative,
    );

    final val2 = PercentageValidation.validateNumber(
      input2Controller.text,
      fieldName: label2,
      allowZero: input2AllowZero,
      allowNegative: allowNegative,
    );

    if (val1 != null || val2 != null) {
      _input1Error = val1;
      _input2Error = val2;
      _calculationResult = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _calculationResult = null;
    notifyListeners();

    // Standard high-end simulated calculation loading speed
    await Future.delayed(const Duration(milliseconds: 600));

    final num1 = double.parse(input1Controller.text.trim());
    final num2 = double.parse(input2Controller.text.trim());

    PercentageResultModel result;

    switch (_selectedTabIndex) {
      case 0:
        result = _calculatorService.calculatePercentageOfNumber(num1, num2);
        break;
      case 1:
        result = _calculatorService.calculateWhatPercentage(num1, num2);
        break;
      case 2:
        result = _calculatorService.calculatePercentageIncrease(num1, num2);
        break;
      case 3:
        result = _calculatorService.calculatePercentageDecrease(num1, num2);
        break;
      case 4:
        result = _calculatorService.calculatePercentageDifference(num1, num2);
        break;
      case 5:
        result = _calculatorService.calculateProfitPercentage(num1, num2);
        break;
      case 6:
        result = _calculatorService.calculateLossPercentage(num1, num2);
        break;
      case 7:
        result = _calculatorService.calculateDiscount(num1, num2);
        break;
      case 8:
        result = _calculatorService.calculateMarkup(num1, num2);
        break;
      case 9:
        result = _calculatorService.calculateMargin(num1, num2);
        break;
      case 10:
        result = _calculatorService.calculatePercentageChange(num1, num2);
        break;
      case 11:
        result = _calculatorService.calculateCommission(num1, num2);
        break;
      default:
        result = _calculatorService.calculatePercentageOfNumber(num1, num2);
    }

    _calculationResult = result;
    _history.insert(0, result);
    _isLoading = false;
    notifyListeners();
  }

  /// Restores a calculation from history
  void loadHistoryItem(PercentageResultModel item) {
    int tabIndex = 0;
    for (int i = 0; i < percentageCalculatorsMeta.length; i++) {
      if (percentageCalculatorsMeta[i]['name'] == item.calculationType) {
        tabIndex = i;
        break;
      }
    }

    _selectedTabIndex = tabIndex;
    
    // Load input values back in correct order
    final keys = item.inputValues.keys.toList();
    if (keys.length >= 2) {
      input1Controller.text = item.inputValues[keys[0]]!.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
      input2Controller.text = item.inputValues[keys[1]]!.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    }

    _calculationResult = item;
    _clearValidationErrors();
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void deleteHistoryItem(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeAt(index);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    input1Controller.dispose();
    input2Controller.dispose();
    super.dispose();
  }
}
