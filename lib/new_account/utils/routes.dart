import 'package:flutter/material.dart';
import 'package:enquiry_app/new_account/screens/create_account_screen.dart';
import 'package:enquiry_app/new_account/screens/sms_otp_screen.dart';
import 'package:enquiry_app/new_account/screens/whatsapp_otp_screen.dart';
import 'package:enquiry_app/new_account/screens/email_screen.dart';
import 'package:enquiry_app/new_account/screens/email_otp_screen.dart';
import 'package:enquiry_app/new_account/screens/profile_screen.dart';
import 'package:enquiry_app/new_account/screens/password_screen.dart';
import 'package:enquiry_app/new_account/screens/registration_success_screen.dart';

class RegistrationRoutes {
  RegistrationRoutes._();

  static Route fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static void toPhone(BuildContext context) {
    Navigator.of(context).push(fadeRoute(const CreateAccountScreen()));
  }

  static void toSmsOtp(BuildContext context) {
    Navigator.of(context).push(fadeRoute(const SmsOtpScreen()));
  }

  static void toWhatsappOtp(BuildContext context) {
    Navigator.of(context).push(fadeRoute(const WhatsappOtpScreen()));
  }

  static void toEmail(BuildContext context) {
    Navigator.of(context).push(fadeRoute(const EmailScreen()));
  }

  static void toEmailOtp(BuildContext context) {
    Navigator.of(context).push(fadeRoute(const EmailOtpScreen()));
  }

  static void toProfile(BuildContext context) {
    Navigator.of(context).push(fadeRoute(const ProfileScreen()));
  }

  static void toPassword(BuildContext context) {
    Navigator.of(context).push(fadeRoute(const PasswordScreen()));
  }

  static void toSuccess(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      fadeRoute(const RegistrationSuccessScreen()),
      (route) => false,
    );
  }
}
