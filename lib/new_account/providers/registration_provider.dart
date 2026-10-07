import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:enquiry_app/new_account/services/registration_repository.dart';
import 'package:enquiry_app/new_account/models/register_model.dart';
import 'package:enquiry_app/providers/riverpod_providers.dart';
import 'package:enquiry_app/new_account/utils/constants.dart';
import 'package:enquiry_app/appcontroler/appcontroler/device_service.dart';
import 'package:enquiry_app/services/custom_flow_service.dart';
import 'package:enquiry_app/utils/api_debug_logger.dart';

class RegistrationProvider extends ChangeNotifier {
  final RegistrationRepository _repository = RegistrationRepository();

  // Registration data
  String _phone = '';
  String _email = '';
  String _fullName = '';
  String _address = '';
  String _password = '';

  // Email OTP tracking
  int _emailOtpResendCount = 0;
  int _emailOtpWrongAttempts = 0;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  // Getters
  String get phone => _phone;
  String get email => _email;
  String get fullName => _fullName;
  String get address => _address;
  String get password => _password;

  int get emailOtpResendCount => _emailOtpResendCount;
  int get emailOtpWrongAttempts => _emailOtpWrongAttempts;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;

  // Setters
  void setPhone(String val) {
    _phone = val.replaceAll(RegExp(r'[^\d]'), '');
    notifyListeners();
  }

  void setEmail(String val) {
    _email = val.trim();
    notifyListeners();
  }

  void setProfileDetails(String name, String addr) {
    _fullName = name.trim();
    _address = addr.trim();
    notifyListeners();
  }

  void setPassword(String pass) {
    _password = pass;
    notifyListeners();
  }

  void reset() {
    _phone = '';
    _email = '';
    _fullName = '';
    _address = '';
    _password = '';
    _emailOtpResendCount = 0;
    _emailOtpWrongAttempts = 0;
    _isLoading = false;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // API wrappers
  Future<bool> checkPhoneExists() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.checkPhone(_phone);
      _isLoading = false;
      notifyListeners();
      return res.exists;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return true; // Stop flow on error just to be safe
    }
  }

  Future<bool> checkEmailExists() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.checkEmail(_email);
      _isLoading = false;
      notifyListeners();
      return res.exists;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return true; // Stop flow on error
    }
  }

  Future<bool> sendEmailOtpCode() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.sendEmailOtp(_email);
      _isLoading = false;
      if (success) {
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to send OTP to email';
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

  Future<bool> resendEmailOtpCode() async {
    if (_emailOtpResendCount >= 3) {
      _errorMessage = 'Maximum resend limit reached';
      notifyListeners();
      return false;
    }

    final success = await sendEmailOtpCode();
    if (success) {
      _emailOtpResendCount++;
      notifyListeners();
    }
    return success;
  }

  Future<bool> verifyEmailOtpCode(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.verifyEmailOtp(_email, code);
      _isLoading = false;
      if (success) {
        notifyListeners();
        return true;
      } else {
        _emailOtpWrongAttempts++;
        _errorMessage = 'Invalid verification code. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _emailOtpWrongAttempts++;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  // Registration & Session storage Setup & Auto Login
  Future<bool> performRegistrationAndAutoLogin(BuildContext context, WidgetRef ref) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Create account
      final regReq = RegisterRequest(
        email: _email,
        password: _password,
        userName: _fullName,
        address: _address,
      );
      final regRes = await _repository.registerUser(regReq);

      if (!regRes.isSuccess) {
        _isLoading = false;
        _errorMessage = regRes.message ?? 'Registration failed';
        notifyListeners();
        return false;
      }

      // 2. Auto Login (using existing authenticate API)
      final loginRes = await _repository.login(_email, _password);
      if (!loginRes.isSuccess) {
        _isLoading = false;
        _errorMessage = loginRes.message ?? 'Auto login failed';
        notifyListeners();
        return false;
      }

      // 3. Save session in storage exactly like login
      final storageService = ref.read(storageServiceProvider);
      
      final String deviceId = await DeviceService.getDeviceId();
      await storageService.setUserDeviceId(deviceId);

      if (loginRes.token != null) {
        await storageService.setAuthToken(loginRes.token!);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', loginRes.token!);
      }

      await storageService.setLoggedIn(true);
      await storageService.setUserRole(loginRes.userType.isNotEmpty ? loginRes.userType : 'user');
      
      if (loginRes.userMainId.isNotEmpty) {
        await storageService.setUserId(loginRes.userMainId);
      }
      
      await storageService.setUserName(
        loginRes.userName.isNotEmpty ? loginRes.userName : (_email.isNotEmpty ? _email.split('@').first : '')
      );
      await storageService.setUserEmail(_email);
      await storageService.setUserPhone(_phone);

      final now = DateTime.now();
      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
      await storageService.setUserLastLogin(formattedDate);

      // Save cookie and other session values in preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_registered', true);
      await prefs.remove('synced_session_${loginRes.userMainId}');

      // 4. Custom flow app validation
      final customCheckOk = await CustomFlowService.checkLoginAppToken(loginRes.userMainId, loginRes.token ?? '');
      if (!customCheckOk) {
        _isLoading = false;
        CustomFlowService.redirectToUpdateScreen();
        return false;
      }

      // 5. Get location details
      Position? position;
      try {
        final permission = await Permission.location.status;
        if (permission.isGranted) {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          ).timeout(const Duration(seconds: 10));
        }
      } catch (e) {
        print("Geolocator error during registration: $e");
      }

      final double lat = position?.latitude ?? 11.0168;
      final double lon = position?.longitude ?? 76.9558;

      String locationName = 'Coimbatore, Tamil Nadu, India';
      if (position != null) {
        locationName = await _reverseGeocode(lat, lon);
      }
      await prefs.setString('user_location_name', locationName);
      await storageService.setUserLocation(locationName);

      // 6. Send User Login Tracking
      final packageInfo = await PackageInfo.fromPlatform();
      final String appName = packageInfo.appName.isNotEmpty ? packageInfo.appName : 'User App';
      
      try {
        final trackingBody = {
          "app_id": "USERAPP-95386",
          "userid": loginRes.userMainId,
          "username_or_email": _email,
          "ime_number": deviceId,
          "latitude": lat.toString(),
          "longitude": lon.toString(),
          "app_name": appName,
        };

        final trackingClient = ApiDebugLogger.wrapClient(http.Client());
        await trackingClient.post(
          Uri.parse("https://mobileadmin.srivagroups.in/api/userlogin/received"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(trackingBody),
        ).timeout(const Duration(seconds: 10));
        trackingClient.close();
      } catch (e) {
        print("Login tracking error during registration: $e");
      }

      // 7. Load User details from endpoints
      // GET api/login/{userid}
      // GET api/user_register/main/{userid}
      try {
        final cookies = prefs.getString('stored_cookies');
        final profileRes = await _repository.loadUserProfile(
          loginRes.userMainId,
          authToken: loginRes.token,
          cookies: cookies,
        );
        
        // Cache detailed profile values
        final rawData = profileRes['data'];
        Map<String, dynamic> userDetails = {};
        if (rawData is Map) {
          if (rawData.containsKey('data') && rawData['data'] is Map) {
            userDetails = Map<String, dynamic>.from(rawData['data']);
          } else {
            userDetails = Map<String, dynamic>.from(rawData);
          }
        }
        if (userDetails.isNotEmpty) {
          final String phone = userDetails['phone_number']?.toString() ??
              userDetails['phone']?.toString() ?? '';
          if (phone.isNotEmpty) {
            await storageService.setUserPhone(phone);
            _phone = phone;
          }
          final String name = userDetails['user_name']?.toString() ?? '';
          if (name.isNotEmpty) {
            await storageService.setUserName(name);
            _fullName = name;
          }
        }
      } catch (e) {
        print("Error fetching profile after registration: $e");
      }

      try {
        final cookies = prefs.getString('stored_cookies');
        // Call user_register/main/{userid}
        await _repository.loadUserRegisterMain(
          loginRes.userMainId,
          authToken: loginRes.token,
          cookies: cookies,
        );
      } catch (e) {
        print("Error calling user_register/main/ after registration: $e");
      }

      // 8. Fetch and store business categories
      try {
        final cookies = prefs.getString('stored_cookies');
        final catRes = await _repository.fetchCategories(
          loginRes.userMainId,
          authToken: loginRes.token,
          cookies: cookies,
        );

        final Set<String> primarySet = {};
        final Set<String> subSet = {};

        void findCategories(dynamic obj) {
          if (obj is Map) {
            if (obj.containsKey('primary_categories') && obj['primary_categories'] is List) {
              for (var p in obj['primary_categories']) {
                if (p is Map && p['name'] != null && p['name'].toString().trim().isNotEmpty) {
                  primarySet.add(p['name'].toString().trim());
                } else if (p is String && p.trim().isNotEmpty) {
                  primarySet.add(p.trim());
                }
              }
            }
            if (obj.containsKey('sub_categories') && obj['sub_categories'] is List) {
              for (var s in obj['sub_categories']) {
                if (s is Map && s['name'] != null && s['name'].toString().trim().isNotEmpty) {
                  subSet.add(s['name'].toString().trim());
                } else if (s is String && s.trim().isNotEmpty) {
                  subSet.add(s.trim());
                }
              }
            }
            for (var value in obj.values) {
              findCategories(value);
            }
          } else if (obj is List) {
            for (var elem in obj) {
              findCategories(elem);
            }
          }
        }

        findCategories(catRes);
        await storageService.setUserPrimaryCategories(primarySet.toList());
        await storageService.setUserSubCategories(subSet.toList());
      } catch (e) {
        print("Error fetching categories during registration: $e");
      }

      // 9. Initialize Security Settings
      final securityManager = ref.read(securityManagerProvider);
      final int userIdInt = int.tryParse(loginRes.userMainId) ?? 12;
      await securityManager.initializeSecurity(userIdInt).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print("SecurityManager: Security initialization timed out during registration.");
        },
      );

      _isSuccess = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    final client = ApiDebugLogger.wrapClient(http.Client());
    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1",
      );
      final response = await client.get(
        url,
        headers: {
          "User-Agent": "lockscreen_app/1.0",
          "Accept-Language": "en",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final address = decoded['address'];
          if (address is Map) {
            final city = address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? address['county'] ?? '';
            final state = address['state'] ?? '';
            final country = address['country'] ?? '';

            final List<String> parts = [];
            if (city.toString().isNotEmpty) parts.add(city.toString());
            if (state.toString().isNotEmpty) parts.add(state.toString());
            if (country.toString().isNotEmpty) parts.add(country.toString());

            if (parts.isNotEmpty) {
              return parts.join(", ");
            }
          }
          final displayName = decoded['display_name'];
          if (displayName != null) {
            return displayName.toString();
          }
        }
      }
    } catch (e) {
      print("Reverse geocoding error during registration: $e");
    } finally {
      client.close();
    }
    return "Coimbatore, Tamil Nadu, India";
  }
}

final registrationProvider = ChangeNotifierProvider((ref) {
  return RegistrationProvider();
});
