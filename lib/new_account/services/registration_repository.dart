import 'package:enquiry_app/new_account/services/registration_api.dart';
import 'package:enquiry_app/new_account/models/check_phone_model.dart';
import 'package:enquiry_app/new_account/models/sms_send_model.dart';
import 'package:enquiry_app/new_account/models/otp_verify_model.dart';
import 'package:enquiry_app/new_account/models/check_email_model.dart';
import 'package:enquiry_app/new_account/models/register_model.dart';
import 'package:enquiry_app/new_account/models/login_model.dart';

class RegistrationRepository {
  final RegistrationApiService _apiService = RegistrationApiService();

  Future<CheckPhoneResponse> checkPhone(String mobile) {
    return _apiService.checkPhone(mobile);
  }

  Future<SmsSendResponse> sendMobileOtp({
    required String mobileNumber,
    required String flowType,
  }) {
    return _apiService.sendMobileOtp(
      mobileNumber: mobileNumber,
      flowType: flowType,
    );
  }

  Future<OtpVerifyResponse> verifyMobileOtp({
    required String mobileNumber,
    required String verificationId,
    required String code,
  }) {
    return _apiService.verifyMobileOtp(
      mobileNumber: mobileNumber,
      verificationId: verificationId,
      code: code,
    );
  }

  Future<CheckEmailResponse> checkEmail(String email) {
    return _apiService.checkEmail(email);
  }

  Future<bool> sendEmailOtp(String email) {
    return _apiService.sendEmailOtp(email);
  }

  Future<bool> verifyEmailOtp(String email, String otp) {
    return _apiService.verifyEmailOtp(email, otp);
  }

  Future<RegisterResponse> registerUser(RegisterRequest request) {
    return _apiService.registerUser(request);
  }

  Future<LoginResponse> login(String email, String password) {
    return _apiService.login(email, password);
  }

  Future<Map<String, dynamic>> loadUserProfile(String userId, {String? authToken, String? cookies}) {
    return _apiService.loadUserProfile(userId, authToken: authToken, cookies: cookies);
  }

  Future<Map<String, dynamic>> loadUserRegisterMain(String userId, {String? authToken, String? cookies}) {
    return _apiService.loadUserRegisterMain(userId, authToken: authToken, cookies: cookies);
  }

  Future<Map<String, dynamic>> fetchCategories(String userMainId, {String? authToken, String? cookies}) {
    return _apiService.fetchCategories(userMainId, authToken: authToken, cookies: cookies);
  }
}
