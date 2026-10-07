import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import 'gst/screens/gst_calculator_screen.dart';
import 'interest/screens/interest_calculator_screen.dart';
import 'percentage/screens/percentage_calculator_screen.dart';
import 'tax/screens/tax_calculator_screen.dart';

class FinanceCalculatorHubScreen extends StatelessWidget {
  const FinanceCalculatorHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgGradientColors = isDarkMode
        ? AppTheme.darkBackgroundGradient
        : AppTheme.lightBackgroundGradient;

    final primaryColor = isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E);

    // List of calculators for the hub
    final List<Map<String, dynamic>> calculators = [
      {
        'title': 'GST Calculator',
        'desc': 'Compute exclusive & inclusive GST, CGST, SGST, and IGST breakdowns.',
        'icon': Icons.calculate_rounded,
        'isActive': true,
        'route': const GstCalculatorScreen(),
      },
      {
        'title': 'Interest Calculator',
        'desc': 'Compute Simple Interest (SI) and Compound Interest (CI) over time.',
        'icon': Icons.trending_up_rounded,
        'isActive': true,
        'route': const InterestCalculatorScreen(initialTabIndex: 0),
      },
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Finance Hub',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        leading: Padding(
          padding: EdgeInsets.all(8.r),
          child: CircleAvatar(
            backgroundColor: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.r,
                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgGradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                Text(
                  'Financial Calculator Suite',
                  style: GoogleFonts.outfit(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Perform complex calculations instantly with step-by-step guides.',
                  style: GoogleFonts.outfit(
                    fontSize: 13.sp,
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
                SizedBox(height: 20.h),
                Expanded(
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: calculators.length,
                    itemBuilder: (context, index) {
                      final item = calculators[index];
                      final isActive = item['isActive'] as bool;
                      
                      return GestureDetector(
                        onTap: () {
                          if (isActive) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => item['route'] as Widget),
                            );
                          } else {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item['title']} is coming soon in a future update!'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isActive
                                  ? primaryColor.withOpacity(0.4)
                                  : (isDarkMode ? const Color(0xFF334155).withOpacity(0.3) : Colors.black.withOpacity(0.04)),
                              width: isActive ? 1.5 : 1,
                            ),
                            color: isActive
                                ? (isDarkMode ? const Color(0xFF151B2C) : Colors.white)
                                : (isDarkMode ? const Color(0xFF1E293B).withOpacity(0.4) : const Color(0xFFF1F5F9).withOpacity(0.6)),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.08),
                                      blurRadius: 12.r,
                                      offset: Offset(0, 4.h),
                                    )
                                  ]
                                : [],
                          ),
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon & Badge Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.r),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? primaryColor.withOpacity(0.12)
                                          : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      color: isActive
                                          ? primaryColor
                                          : (isDarkMode ? Colors.white30 : Colors.black38),
                                      size: 24.r,
                                    ),
                                  ),
                                  if (!isActive)
                                    Icon(
                                      Icons.lock_outline_rounded,
                                      size: 16.r,
                                      color: isDarkMode ? Colors.white24 : Colors.black26,
                                    )
                                  else
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        'ACTIVE',
                                        style: GoogleFonts.outfit(
                                          fontSize: 8.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const Spacer(),
                              // Title
                              Text(
                                item['title'] as String,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
                                      : (isDarkMode ? Colors.white38 : Colors.black45),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              // Description
                              Text(
                                item['desc'] as String,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 10.sp,
                                  height: 1.3,
                                  color: isActive
                                      ? (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
                                      : (isDarkMode ? Colors.white12 : Colors.black26),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
