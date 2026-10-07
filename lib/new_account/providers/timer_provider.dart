import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimerProvider extends ChangeNotifier {
  Timer? _timer;
  int _secondsRemaining = 30;

  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _timer != null && _timer!.isActive;
  bool get isCompleted => _secondsRemaining == 0;

  void startTimer() {
    _timer?.cancel();
    _secondsRemaining = 30;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        stopTimer();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void resetTimer() {
    stopTimer();
    _secondsRemaining = 30;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerProvider = ChangeNotifierProvider.autoDispose((ref) {
  final provider = TimerProvider();
  ref.onDispose(() => provider.dispose());
  return provider;
});
