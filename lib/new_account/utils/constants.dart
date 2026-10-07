import 'package:flutter/material.dart';

class RegistrationConstants {
  RegistrationConstants._();

  // API base URL and endpoints
  static const String baseUserUrl = 'https://user.jobes24x7.com';
  static const String baseMessageCentralUrl = 'https://cpaas.messagecentral.com';

  static const String checkPhonePath = '/api/login/check-phone';
  static const String checkEmailPath = '/api/login/check-email';
  static const String sendEmailOtpPath = '/api/send-otp';
  static const String verifyEmailOtpPath = '/api/verify-otp';
  static const String createUserPath = '/api/login/create';
  static const String authenticatePath = '/api/login/authenticate';
  static const String getProfilePath = '/api/login';
  static const String getRegistrationMainPath = '/api/user_register/main';
  static const String fetchCategoriesPath = '/api/business-cre/main';

  // Message Central Config
  static const String mcCustomerId = 'C-836DB70B5587493';
  static const String mcAuthToken =
      'eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJDLTgzNkRCNzBCNTU4NzQ5MyIsImlhdCI6MTc3MzA0NzU5OSwiZXhwIjoxOTMwNzI3NTk5fQ.pgnC_7IQgwfh3QGRuu4APflRX9VCpt_RQNR-QX1SP425KXn4PUmAohdQTWtEWhDx7Z9lOVfAevCVHCed4uemew';

  // Colors matching existing theme
  static const List<Color> primaryGradient = [
    Color(0xFF0F766E),
    Color(0xFF0284C7),
    Color(0xFF3B82F6),
  ];

  static const Color accentColor = Color(0xFF0D9488);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
}
