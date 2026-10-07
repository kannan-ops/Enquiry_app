import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TimerWidget extends StatelessWidget {
  final int secondsRemaining;

  const TimerWidget({
    super.key,
    required this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final minutesStr = (secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final secondsStr = (secondsRemaining % 60).toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.access_time_filled_rounded,
          size: 16.w,
          color: secondsRemaining == 0
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: 6.w),
        Text(
          '$minutesStr:$secondsStr',
          style: GoogleFonts.outfit(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: secondsRemaining == 0
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
