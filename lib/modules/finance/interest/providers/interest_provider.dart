import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interest_result_model.dart';
import '../services/interest_calculator_service.dart';
import '../utils/interest_validation.dart';

final interestProvider = ChangeNotifierProvider<InterestProvider>((ref) {
  return InterestProvider();
});

class InterestProvider extends ChangeNotifier {
  final InterestCalculatorService _calculatorService = InterestCalculatorService();

  // Controllers
  final TextEditingController principalController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();

  // Mode Selection
  int _selectedTabIndex = 0; // 0: Simple, 1: Compound, 2: EMI, 3: FD, 4: RD, 5: Daily
  
  // Inputs
  String _selectedTimeUnit = 'Years';
  String _selectedCompoundFrequency = 'Quarterly';

  // Results & History
  InterestResultModel? _calculationResult;
  final List<InterestResultModel> _history = [];
  final Set<String> _favorites = {};

  // UI States
  bool _isLoading = false;
  String? _principalError;
  String? _rateError;
  String? _timeError;

  InterestProvider() {
    _loadFavorites();
  }

  // Getters
  int get selectedTabIndex => _selectedTabIndex;
  String get selectedTimeUnit => _selectedTimeUnit;
  String get selectedCompoundFrequency => _selectedCompoundFrequency;
  InterestResultModel? get calculationResult => _calculationResult;
  List<InterestResultModel> get history => _history;
  Set<String> get favorites => _favorites;
  bool get isLoading => _isLoading;
  
  String? get principalError => _principalError;
  String? get rateError => _rateError;
  String? get timeError => _timeError;

  // Favorites System Persistence
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList('interest_calculator_favorites');
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
      await prefs.setStringList('interest_calculator_favorites', _favorites.toList());
    } catch (_) {}
  }

  bool isFavorite(String calcName) => _favorites.contains(calcName);

  // Setters & UI controls
  void setSelectedTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      _clearValidationErrors();
      _calculationResult = null; // reset result for fresh view

      // Smart Defaults for Time Units & Frequencies based on the type
      switch (index) {
        case 0: // Simple
          _selectedTimeUnit = 'Years';
          break;
        case 1: // Compound
          _selectedTimeUnit = 'Years';
          _selectedCompoundFrequency = 'Quarterly';
          break;
        case 2: // EMI
          _selectedTimeUnit = 'Years';
          break;
        case 3: // FD
          _selectedTimeUnit = 'Years';
          _selectedCompoundFrequency = 'Quarterly';
          break;
        case 4: // RD
          _selectedTimeUnit = 'Months';
          _selectedCompoundFrequency = 'Quarterly';
          break;
        case 5: // Daily
          _selectedTimeUnit = 'Days';
          break;
      }
      notifyListeners();
    }
  }

  void setTimeUnit(String unit) {
    if (_selectedTimeUnit != unit) {
      _selectedTimeUnit = unit;
      notifyListeners();
    }
  }

  void setCompoundFrequency(String frequency) {
    if (_selectedCompoundFrequency != frequency) {
      _selectedCompoundFrequency = frequency;
      notifyListeners();
    }
  }

  void _clearValidationErrors() {
    _principalError = null;
    _rateError = null;
    _timeError = null;
  }

  /// Reset all inputs and active states.
  void reset() {
    principalController.clear();
    rateController.clear();
    timeController.clear();
    _calculationResult = null;
    _clearValidationErrors();
    _isLoading = false;
    notifyListeners();
  }

  /// Perform calculation.
  Future<void> calculate() async {
    _clearValidationErrors();

    // Determine Labels based on Active Mode
    String principalLabel = 'Principal';
    String timeLabel = 'Tenure';
    if (_selectedTabIndex == 2) principalLabel = 'Loan Amount';
    if (_selectedTabIndex == 3) principalLabel = 'Deposit Amount';
    if (_selectedTabIndex == 4) {
      principalLabel = 'Monthly Deposit';
      timeLabel = 'Months';
    }
    if (_selectedTabIndex == 5) {
      principalLabel = 'Amount';
      timeLabel = 'Days';
    }

    // Run Validations
    final pVal = InterestValidation.validateAmount(principalController.text, fieldName: principalLabel);
    final rVal = InterestValidation.validateRate(rateController.text);
    final tVal = InterestValidation.validateTime(timeController.text, fieldName: timeLabel);

    if (pVal != null || rVal != null || tVal != null) {
      _principalError = pVal;
      _rateError = rVal;
      _timeError = tVal;
      _calculationResult = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _calculationResult = null;
    notifyListeners();

    // Loading transition delay
    await Future.delayed(const Duration(milliseconds: 600));

    final P = double.parse(principalController.text.trim());
    final R = double.parse(rateController.text.trim());
    final T = double.parse(timeController.text.trim());

    InterestResultModel result;

    switch (_selectedTabIndex) {
      case 0: // Simple
        result = _calculatorService.calculateSimpleInterest(P, R, T, _selectedTimeUnit);
        break;
      case 1: // Compound
        result = _calculatorService.calculateCompoundInterest(P, R, T, _selectedCompoundFrequency);
        break;
      case 2: // EMI
        result = _calculatorService.calculateEMI(P, R, T, _selectedTimeUnit);
        break;
      case 3: // FD
        result = _calculatorService.calculateFD(P, R, T);
        break;
      case 4: // RD
        result = _calculatorService.calculateRD(P, R, T);
        break;
      case 5: // Daily
        result = _calculatorService.calculateDailyInterest(P, R, T);
        break;
      default:
        result = _calculatorService.calculateSimpleInterest(P, R, T, _selectedTimeUnit);
    }

    _calculationResult = result;
    _history.insert(0, result);
    _isLoading = false;
    notifyListeners();
  }

  /// Load a historic calculation.
  void loadHistoryItem(InterestResultModel item) {
    int tabIndex = 0;
    switch (item.calculationType) {
      case 'Simple Interest':
        tabIndex = 0;
        break;
      case 'Compound Interest':
        tabIndex = 1;
        break;
      case 'EMI':
        tabIndex = 2;
        break;
      case 'Fixed Deposit':
        tabIndex = 3;
        break;
      case 'Recurring Deposit':
        tabIndex = 4;
        break;
      case 'Daily Interest':
        tabIndex = 5;
        break;
    }

    _selectedTabIndex = tabIndex;
    _selectedTimeUnit = item.timeUnit;
    _selectedCompoundFrequency = item.compoundFrequency ?? 'Quarterly';

    // Populate controllers
    if (tabIndex == 4) {
      // For RD, load monthly installment from principal division (or we store it properly)
      // Wait, principal in RD model is set to totalDeposit = deposit * months. So monthlyDeposit = principal / months
      final monthlyDeposit = item.principal / item.time;
      principalController.text = monthlyDeposit.toStringAsFixed(2);
    } else {
      principalController.text = item.principal.toStringAsFixed(2);
    }
    rateController.text = item.interestRate.toStringAsFixed(2);
    timeController.text = item.time.toStringAsFixed(2);

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
    principalController.dispose();
    rateController.dispose();
    timeController.dispose();
    super.dispose();
  }
}
