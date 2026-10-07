import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/tax_constants.dart';

class TaxTypeTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Set<String> favorites;
  final Function(String) onFavoriteToggled;

  const TaxTypeTabs({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.favorites,
    required this.onFavoriteToggled,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E);

    return SizedBox(
      height: 80.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: taxCalculatorsMeta.length,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemBuilder: (context, index) {
          final meta = taxCalculatorsMeta[index];
          final name = meta['name'] as String;
          final short = meta['short'] as String;
          final icon = meta['icon'] as IconData;
          final isSelected = selectedIndex == index;
          final isFav = favorites.contains(name);

          return GestureDetector(
            onTap: () => onTabSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 105.w,
              margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
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
                      : (isDarkMode ? const Color(0xFF334155).withOpacity(0.5) : Colors.black.withOpacity(0.04)),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.25),
                          blurRadius: 8.r,
                          offset: Offset(0, 3.h),
                        )
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  // Favorite Star Button
                  Positioned(
                    top: 2.h,
                    right: 2.w,
                    child: GestureDetector(
                      onTap: () => onFavoriteToggled(name),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          isFav ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 14.r,
                          color: isFav
                              ? (isSelected ? Colors.amber : Colors.amber.shade600)
                              : (isSelected ? Colors.white38 : (isDarkMode ? Colors.white30 : Colors.black26)),
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 20.r,
                            color: isSelected
                                ? Colors.white
                                : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            short,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 10.sp,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
