import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enquiry_app/theme/app_theme.dart';
import 'package:enquiry_app/new_account/utils/routes.dart';
import 'package:enquiry_app/new_account/providers/registration_provider.dart';
import 'package:enquiry_app/new_account/providers/otp_provider.dart';
import 'package:enquiry_app/new_account/providers/timer_provider.dart';
import 'package:enquiry_app/new_account/widgets/gradient_header.dart';
import 'package:enquiry_app/new_account/widgets/otp_box.dart';
import 'package:enquiry_app/new_account/widgets/timer_widget.dart';
import 'package:enquiry_app/new_account/widgets/resend_widget.dart';
import 'package:enquiry_app/new_account/widgets/attempt_counter.dart';
import 'package:enquiry_app/new_account/widgets/primary_button.dart';
import 'package:enquiry_app/new_account/widgets/loading_overlay.dart';

class WhatsappOtpScreen extends ConsumerStatefulWidget {
  const WhatsappOtpScreen({super.key});

  @override
  ConsumerState<WhatsappOtpScreen> createState() => _WhatsappOtpScreenState();
}

class _WhatsappOtpScreenState extends ConsumerState<WhatsappOtpScreen> {
  String _otpCode = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timerProvider.notifier).startTimer();
    });
  }

  void _handleResend() async {
    final regState = ref.read(registrationProvider);
    final otpNotifier = ref.read(otpProvider);

    if (otpNotifier.resendCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('WhatsApp resend limit reached. Switching to Email verification...'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      
      RegistrationRoutes.toEmail(context);
      return;
    }

    final success = await otpNotifier.resendOtp(
      mobileNumber: regState.phone,
      flowType: 'WHATSAPP',
    );

    if (success && mounted) {
      ref.read(timerProvider.notifier).startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP code resent successfully via WhatsApp'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleVerify() async {
    if (_otpCode.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the full 4-digit OTP code'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final regState = ref.read(registrationProvider);
    final otpNotifier = ref.read(otpProvider);

    final success = await otpNotifier.verifyOtp(
      mobileNumber: regState.phone,
      code: _otpCode,
    );

    if (!mounted) return;

    if (success) {
      ref.read(timerProvider.notifier).stopTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('WhatsApp verification successful!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      final regNotifier = ref.read(registrationProvider);
      regNotifier.setEmail('${regNotifier.phone}@gmail.com');
      RegistrationRoutes.toProfile(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpNotifier.errorMessage ?? 'Incorrect verification code'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final regState = ref.watch(registrationProvider);
    final otpState = ref.watch(otpProvider);
    final timerState = ref.watch(timerProvider);

    return LoadingOverlay(
      isLoading: otpState.isLoading,
      message: 'Verifying WhatsApp code...',
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? AppTheme.darkBackgroundGradient
                  : AppTheme.lightBackgroundGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GradientHeader(
                    title: 'WhatsApp OTP Verification',
                    subtitle: 'We sent a 4-digit verification code to your WhatsApp at +91 ${regState.phone}',
                    icon: Icons.chat_rounded,
                  ),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          OtpBox(
                            length: 4,
                            onChanged: (code) => setState(() => _otpCode = code),
                            onCompleted: (code) {
                              _otpCode = code;
                              _handleVerify();
                            },
                          ),
                          SizedBox(height: 24.h),
                          Center(
                            child: TimerWidget(secondsRemaining: timerState.secondsRemaining),
                          ),
                          SizedBox(height: 16.h),
                          Center(
                            child: AttemptCounter(attempts: otpState.wrongAttempts),
                          ),
                          SizedBox(height: 24.h),
                          ResendWidget(
                            onResend: _handleResend,
                            isTimerActive: timerState.isRunning,
                            resendCount: otpState.resendCount,
                          ),
                          SizedBox(height: 32.h),
                          PrimaryButton(
                            text: 'Verify & Continue',
                            onPressed: _otpCode.length == 4 ? _handleVerify : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
