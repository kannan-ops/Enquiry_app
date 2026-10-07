import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:enquiry_app/theme/app_theme.dart';
import 'package:enquiry_app/new_account/utils/validators.dart';
import 'package:enquiry_app/new_account/utils/routes.dart';
import 'package:enquiry_app/new_account/providers/registration_provider.dart';
import 'package:enquiry_app/new_account/widgets/gradient_header.dart';
import 'package:enquiry_app/new_account/widgets/primary_button.dart';
import 'package:enquiry_app/new_account/widgets/loading_overlay.dart';

class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key});

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final regNotifier = ref.read(registrationProvider);
    regNotifier.setEmail(email);

    // Call check email existence
    final exists = await regNotifier.checkEmailExists();
    if (!mounted) return;

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email already registered'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Send Email OTP
    final success = await regNotifier.sendEmailOtpCode();
    if (!mounted) return;

    if (success) {
      RegistrationRoutes.toEmailOtp(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(regNotifier.errorMessage ?? 'Failed to send OTP to email. Please try again.'),
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

    return LoadingOverlay(
      isLoading: regState.isLoading,
      message: 'Checking email address...',
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
                      title: 'Email Address',
                      subtitle: 'Enter your email address to receive a secure authorization code',
                      icon: Icons.email_rounded,
                      showBackButton: true,
                    ),
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.outfit(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.alternate_email_rounded,
                                  size: 20.w,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                ),
                                labelText: 'Email Address',
                                hintText: 'example@domain.com',
                              ),
                              validator: Validators.validateEmail,
                            ),
                            SizedBox(height: 32.h),
                            PrimaryButton(
                              text: 'Send Verification OTP',
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
