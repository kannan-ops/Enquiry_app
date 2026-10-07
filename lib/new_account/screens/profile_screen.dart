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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    final notifier = ref.read(registrationProvider);
    notifier.setProfileDetails(name, address);
    RegistrationRoutes.toPassword(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                    title: 'Profile Details',
                    subtitle: 'Tell us a bit about yourself to complete your profile',
                    icon: Icons.account_circle_outlined,
                    showBackButton: true,
                  ),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.person_rounded,
                                size: 20.w,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                              ),
                              labelText: 'Full Name',
                              hintText: 'John Doe',
                            ),
                            validator: (value) => Validators.validateRequired(value, 'Full name'),
                          ),
                          SizedBox(height: 20.h),
                          TextFormField(
                            controller: _addressController,
                            keyboardType: TextInputType.streetAddress,
                            maxLines: 3,
                            style: GoogleFonts.outfit(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 36.h),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  size: 20.w,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                ),
                              ),
                              labelText: 'Address',
                              hintText: '123 Main Street, City, Country',
                              alignLabelWithHint: true,
                            ),
                            validator: (value) => Validators.validateRequired(value, 'Address'),
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
    );
  }
}
