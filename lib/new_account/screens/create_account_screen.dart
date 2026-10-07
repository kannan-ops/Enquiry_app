import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enquiry_app/theme/app_theme.dart';
import 'package:enquiry_app/new_account/utils/validators.dart';
import 'package:enquiry_app/new_account/utils/routes.dart';
import 'package:enquiry_app/new_account/providers/registration_provider.dart';
import 'package:enquiry_app/new_account/providers/otp_provider.dart';
import 'package:enquiry_app/new_account/widgets/gradient_header.dart';
import 'package:enquiry_app/new_account/widgets/phone_textfield.dart';
import 'package:enquiry_app/new_account/widgets/primary_button.dart';
import 'package:enquiry_app/new_account/widgets/loading_overlay.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    
    final phone = _phoneController.text.trim();
    final regNotifier = ref.read(registrationProvider);
    regNotifier.setPhone(phone);

    // Call checkPhone
    final exists = await regNotifier.checkPhoneExists();
    
    if (!mounted) return;

    if (exists) {
                        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('This mobile number already exists.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Call OTP dispatch
    final otpNotifier = ref.read(otpProvider);
    otpNotifier.reset(); // clear any previous OTP states
    final otpSent = await otpNotifier.sendOtp(
      mobileNumber: phone,
      flowType: 'SMS',
    );

    if (!mounted) return;

    if (otpSent) {
      RegistrationRoutes.toSmsOtp(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpNotifier.errorMessage ?? 'Failed to send OTP. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final regState = ref.watch(registrationProvider);
    final otpState = ref.watch(otpProvider);
    final isLoading = regState.isLoading || otpState.isLoading;

    return LoadingOverlay(
      isLoading: isLoading,
      message: regState.isLoading ? 'Checking mobile number...' : 'Sending verification code...',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const GradientHeader(
                      title: 'Create Account',
                      subtitle: 'Enter your mobile number to verify and get started',
                      icon: Icons.person_add_alt_1_rounded,
                      showBackButton: true,
                    ),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PhoneTextField(
                              controller: _phoneController,
                              validator: Validators.validatePhone,
                            ),
                            SizedBox(height: 32.h),
                            PrimaryButton(
                              text: 'Continue',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: _handleContinue,
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
      ),
    );
  }
}
