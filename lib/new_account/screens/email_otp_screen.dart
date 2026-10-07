import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enquiry_app/theme/app_theme.dart';
import 'package:enquiry_app/new_account/utils/routes.dart';
import 'package:enquiry_app/new_account/providers/registration_provider.dart';
import 'package:enquiry_app/new_account/providers/timer_provider.dart';
import 'package:enquiry_app/new_account/widgets/gradient_header.dart';
import 'package:enquiry_app/new_account/widgets/otp_box.dart';
import 'package:enquiry_app/new_account/widgets/timer_widget.dart';
import 'package:enquiry_app/new_account/widgets/resend_widget.dart';
import 'package:enquiry_app/new_account/widgets/attempt_counter.dart';
import 'package:enquiry_app/new_account/widgets/primary_button.dart';
import 'package:enquiry_app/new_account/widgets/loading_overlay.dart';

class EmailOtpScreen extends ConsumerStatefulWidget {
  const EmailOtpScreen({super.key});

  @override
  ConsumerState<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends ConsumerState<EmailOtpScreen> {
  String _otpCode = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(timerProvider.notifier).startTimer();
    });
  }

  void _handleResend() async {
    final regNotifier = ref.read(registrationProvider);
    
    final success = await regNotifier.resendEmailOtpCode();

    if (success && mounted) {
      ref.read(timerProvider.notifier).startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP code resent successfully to your email'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(regNotifier.errorMessage ?? 'Failed to resend email OTP.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleVerify() async {
    if (_otpCode.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the 4-digit OTP code'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final regNotifier = ref.read(registrationProvider);

    final success = await regNotifier.verifyEmailOtpCode(_otpCode);

    if (!mounted) return;

    if (success) {
      ref.read(timerProvider.notifier).stopTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email address verified successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      RegistrationRoutes.toProfile(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(regNotifier.errorMessage ?? 'Incorrect verification code'),
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
    final timerState = ref.watch(timerProvider);

    return LoadingOverlay(
      isLoading: regState.isLoading,
      message: 'Verifying email code...',
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
                    title: 'Email OTP Verification',
                    subtitle: 'We sent a 4-digit verification code to ${regState.email}',
                    icon: Icons.mark_email_read_outlined,
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
                            child: AttemptCounter(attempts: regState.emailOtpWrongAttempts),
                          ),
                          SizedBox(height: 24.h),
                          ResendWidget(
                            onResend: _handleResend,
                            isTimerActive: timerState.isRunning,
                            resendCount: regState.emailOtpResendCount,
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
