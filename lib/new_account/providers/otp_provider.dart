import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enquiry_app/new_account/services/registration_repository.dart';

class OtpProvider extends ChangeNotifier {
  final RegistrationRepository _repository = RegistrationRepository();

  String? _verificationId;
  int _resendCount = 0;
  int _wrongAttempts = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isVerified = false;

  String? get verificationId => _verificationId;
  int get resendCount => _resendCount;
  int get wrongAttempts => _wrongAttempts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isVerified => _isVerified;

  void reset() {
    _verificationId = null;
    _resendCount = 0;
    _wrongAttempts = 0;
    _isLoading = false;
    _errorMessage = null;
    _isVerified = false;
    notifyListeners();
  }

  void incrementWrongAttempts() {
    _wrongAttempts++;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendOtp({
    required String mobileNumber,
    required String flowType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.sendMobileOtp(
        mobileNumber: mobileNumber,
        flowType: flowType,
      );

      if (response.verificationId != null) {
        _verificationId = response.verificationId;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = response.message ?? 'Failed to send verification code';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp({
    required String mobileNumber,
    required String flowType,
  }) async {
    if (_resendCount >= 3) {
      _errorMessage = 'Maximum resend limit reached';
      notifyListeners();
      return false;
    }

    final success = await sendOtp(mobileNumber: mobileNumber, flowType: flowType);
    if (success) {
      _resendCount++;
      notifyListeners();
    }
    return success;
  }

  Future<bool> verifyOtp({
    required String mobileNumber,
    required String code,
  }) async {
    if (_verificationId == null) {
      _errorMessage = 'No verification session found';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.verifyMobileOtp(
        mobileNumber: mobileNumber,
        verificationId: _verificationId!,
        code: code,
      );

      _isLoading = false;
      if (response.isSuccess) {
        _isVerified = true;
        notifyListeners();
        return true;
      } else {
        _wrongAttempts++;
        _errorMessage = 'Incorrect verification code. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _wrongAttempts++;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }
}

final otpProvider = ChangeNotifierProvider.autoDispose((ref) {
  return OtpProvider();
});
