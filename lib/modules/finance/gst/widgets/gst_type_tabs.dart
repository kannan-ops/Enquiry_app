import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class GstTypeTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const GstTypeTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      'Exclusive\n(Add GST)',
      'Inclusive\n(Remove GST)',
      'CGST +\nSGST',
      'IGST\nCalculator',
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout: Grid for mobile, single scrollable or spaced cards for larger views
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 2.3,
            ),
            itemCount: tabs.length,
            itemBuilder: (context, index) {
              final isSelected = selectedIndex == index;
              return GestureDetector(
                onTap: () => onTabSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: isSelected
                        ? LinearGradient(
                            colors: isDarkMode
                                ? [const Color(0xFF14B8A6), const Color(0xFF0F766E)]
                                : [const Color(0xFF0F766E), const Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : (isDarkMode ? const Color(0xFF334155).withOpacity(0.5) : Colors.black.withOpacity(0.05)),
                      width: 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E)).withOpacity(0.25),
                              blurRadius: 10.r,
                              offset: Offset(0, 4.h),
                            )
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      child: Text(
                        tabs[index],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
