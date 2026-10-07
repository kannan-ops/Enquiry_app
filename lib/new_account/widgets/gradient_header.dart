import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:enquiry_app/theme/app_theme.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool showBackButton;

  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                  padding: EdgeInsets.all(10.r),
                ),
              )
            else
              const SizedBox(width: 48, height: 48),
            const SizedBox(width: 48, height: 48), // Spacer to balance back button
          ],
        ),
        SizedBox(height: 10.h),
        Center(
          child: Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: AppTheme.primaryGradient,
              ).createShader(bounds),
              child: Icon(
                icon,
                size: 44.r,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 26.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24.h),
      ],
    );
  }
}
