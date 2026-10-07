import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:enquiry_app/new_account/utils/constants.dart';
import 'package:enquiry_app/new_account/models/check_phone_model.dart';
import 'package:enquiry_app/new_account/models/sms_send_model.dart';
import 'package:enquiry_app/new_account/models/otp_verify_model.dart';
import 'package:enquiry_app/new_account/models/check_email_model.dart';
import 'package:enquiry_app/new_account/models/register_model.dart';
import 'package:enquiry_app/new_account/models/login_model.dart';
import 'package:enquiry_app/utils/api_debug_logger.dart';

class RegistrationApiService {
  final http.Client _client = ApiDebugLogger.wrapClient(http.Client());

  Future<CheckPhoneResponse> checkPhone(String mobile) async {
    final cleanMobile = mobile.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse('${RegistrationConstants.baseUserUrl}${RegistrationConstants.checkPhonePath}/$cleanMobile');
    
    final response = await _client.get(
      url,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return CheckPhoneResponse.fromJson(json);
    } else {
      throw Exception('Server returned status code ${response.statusCode}');
    }
  }

  Future<SmsSendResponse> sendMobileOtp({
    required String mobileNumber,
    required String flowType,
  }) async {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse(
      '${RegistrationConstants.baseMessageCentralUrl}/verification/v3/send?'
      'countryCode=91&'
      'customerId=${RegistrationConstants.mcCustomerId}&'
      'flowType=$flowType&'
      'mobileNumber=$cleanMobile',
    );

    final response = await _client.post(
      url,
      headers: {
        'authToken': RegistrationConstants.mcAuthToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return SmsSendResponse.fromJson(json);
    } else {
      throw Exception('Failed to send OTP via $flowType: status ${response.statusCode}');
    }
  }

  Future<OtpVerifyResponse> verifyMobileOtp({
    required String mobileNumber,
    required String verificationId,
    required String code,
  }) async {
    final cleanMobile = mobileNumber.replaceAll(RegExp(r'[^\d]'), '');
    final url = Uri.parse(
      '${RegistrationConstants.baseMessageCentralUrl}/verification/v3/validateOtp?'
      'countryCode=91&'
      'mobileNumber=$cleanMobile&'
      'verificationId=$verificationId&'
      'customerId=${RegistrationConstants.mcCustomerId}&'
      'code=$code',
    );

    final response = await _client.get(
      url,
      headers: {
        'authToken': RegistrationConstants.mcAuthToken,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return OtpVerifyResponse.fromJson(json);
    } else {
      throw Exception('OTP verification request failed');
    }
  }

  Future<CheckEmailResponse> checkEmail(String email) async {
    final url = Uri.parse(
      '${RegistrationConstants.baseUserUrl}${RegistrationConstants.checkEmailPath}/${Uri.encodeComponent(email)}',
    );

    final response = await _client.get(
      url,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return CheckEmailResponse.fromJson(json);
    } else {
      throw Exception('Server returned status code ${response.statusCode}');
    }
  }

  Future<bool> sendEmailOtp(String email) async {
    final url = Uri.parse('${RegistrationConstants.baseUserUrl}${RegistrationConstants.sendEmailOtpPath}');
    
    final response = await _client.post(
      url,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      // Depending on the api schema, check if response code or result is success
      final data = json['data'] ?? json;
      return data['result'] == 'Success' || data['code'] == 200 || data['success'] == true;
    }
    return false;
  }

  Future<bool> verifyEmailOtp(String email, String otp) async {
    final url = Uri.parse('${RegistrationConstants.baseUserUrl}${RegistrationConstants.verifyEmailOtpPath}');
    
    final response = await _client.post(
      url,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] ?? json;
      return data['result'] == 'Success' || data['code'] == 200 || data['success'] == true;
    }
    return false;
  }

  Future<RegisterResponse> registerUser(RegisterRequest request) async {
    final url = Uri.parse('${RegistrationConstants.baseUserUrl}${RegistrationConstants.createUserPath}');
    
    final response = await _client.post(
      url,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return RegisterResponse.fromJson(json);
    } else {
      throw Exception('Registration failed (${response.statusCode}): ${response.body}');
    }
  }

  Future<LoginResponse> login(String email, String password) async {
    final url = Uri.parse('${RegistrationConstants.baseUserUrl}${RegistrationConstants.authenticatePath}');
    
    final response = await _client.post(
      url,
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      
      // Cache cookies from response headers
      final List<String> setCookies = [];
      response.headers.forEach((key, val) {
        if (key.toLowerCase() == 'set-cookie') {
          setCookies.add(val);
        }
      });
      
      final loginRes = LoginResponse.fromJson(json);
      return loginRes;
    } else {
      throw Exception('Auto login authentication failed');
    }
  }

  Future<Map<String, dynamic>> loadUserProfile(String userId, {String? authToken, String? cookies}) async {
    final url = Uri.parse('${RegistrationConstants.baseUserUrl}${RegistrationConstants.getProfilePath}/$userId');
    
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      if (cookies != null && cookies.isNotEmpty) 'Cookie': cookies,
    };

    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile: status ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> loadUserRegisterMain(String userId, {String? authToken, String? cookies}) async {
    final url = Uri.parse('${RegistrationConstants.baseUserUrl}${RegistrationConstants.getRegistrationMainPath}/$userId');
    
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      if (cookies != null && cookies.isNotEmpty) 'Cookie': cookies,
    };

    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user registration main: status ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchCategories(String userMainId, {String? authToken, String? cookies}) async {
    final url = Uri.parse('${RegistrationConstants.baseUserUrl}${RegistrationConstants.fetchCategoriesPath}/$userMainId');
    
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
      if (cookies != null && cookies.isNotEmpty) 'Cookie': cookies,
    };

    final response = await _client.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch categories: status ${response.statusCode}');
    }
  }
}
