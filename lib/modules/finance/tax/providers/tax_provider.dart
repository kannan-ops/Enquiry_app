import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tax_result_model.dart';
import '../services/tax_calculator_service.dart';

final taxProvider = ChangeNotifierProvider<TaxProvider>((ref) {
  return TaxProvider();
});

class TaxProvider extends ChangeNotifier {
  final TaxCalculatorService _calculatorService = TaxCalculatorService();

  // Controllers
  final TextEditingController amountController = TextEditingController();
  final TextEditingController percentageController = TextEditingController();

  // Calculation Results & History
  TaxResultModel? _calculationResult;
  final List<TaxResultModel> _history = [];
  final Set<String> _favorites = {};

  // UI States
  bool _isLoading = false;
  final Map<String, String?> _errors = {};

  TaxProvider() {
    _loadFavorites();
  }

  // Getters
  TaxResultModel? get calculationResult => _calculationResult;
  List<TaxResultModel> get history => _history;
  Set<String> get favorites => _favorites;
  bool get isLoading => _isLoading;
  Map<String, String?> get errors => _errors;

  // Favorites System Persistence
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList('tax_calculator_favorites');
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
      await prefs.setStringList('tax_calculator_favorites', _favorites.toList());
    } catch (_) {}
  }

  bool isFavorite(String calcName) => _favorites.contains(calcName);

  // Reset fields
  void reset() {
    amountController.clear();
    percentageController.clear();
    _errors.clear();
    _calculationResult = _calculatorService.resetCalculation();
    _isLoading = false;
    notifyListeners();
  }

  /// Perform tax calculations
  Future<void> calculate() async {
    _errors.clear();
    
    final validationErrors = _calculatorService.validateTax(
      amountController.text,
      percentageController.text,
    );

    if (validationErrors.isNotEmpty) {
      _errors.addAll(validationErrors);
      _calculationResult = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _calculationResult = null;
    notifyListeners();

    // Simulated loading delay
    await Future.delayed(const Duration(milliseconds: 600));

    final amt = double.parse(amountController.text.trim());
    final pct = double.parse(percentageController.text.trim());

    _calculationResult = _calculatorService.calculateTax(amt, pct);
    _history.insert(0, _calculationResult!);
    _isLoading = false;
    notifyListeners();
  }

  /// Restore calculation from history
  void loadHistoryItem(TaxResultModel item) {
    amountController.text = item.originalAmount.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    percentageController.text = item.taxPercentage.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    _calculationResult = item;
    _errors.clear();
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
    amountController.dispose();
    percentageController.dispose();
    super.dispose();
  }
}
