import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ResendWidget extends StatelessWidget {
  final VoidCallback? onResend;
  final bool isTimerActive;
  final int resendCount;
  final int maxResends;

  const ResendWidget({
    super.key,
    required this.onResend,
    required this.isTimerActive,
    required this.resendCount,
    this.maxResends = 3,
  });

  @override
  Widget build(BuildContext context) {
    final canResend = !isTimerActive && resendCount < maxResends && onResend != null;
    final limitReached = resendCount >= maxResends;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the OTP? ",
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        GestureDetector(
          onTap: canResend ? onResend : null,
          child: Text(
            limitReached ? "Limit reached" : "Resend",
            style: GoogleFonts.outfit(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: canResend
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              decoration: canResend ? TextDecoration.underline : TextDecoration.none,
            ),
          ),
        ),
        if (!limitReached) ...[
          SizedBox(width: 8.w),
          Text(
            '($resendCount/$maxResends)',
            style: GoogleFonts.outfit(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ],
    );
  }
}
