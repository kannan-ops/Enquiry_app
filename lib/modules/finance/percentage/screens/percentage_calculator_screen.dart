import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';
import '../providers/percentage_provider.dart';
import '../widgets/percentage_type_tabs.dart';
import '../widgets/percentage_input_card.dart';
import '../widgets/percentage_result_card.dart';
import '../widgets/percentage_history_card.dart';

class PercentageCalculatorScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const PercentageCalculatorScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<PercentageCalculatorScreen> createState() => _PercentageCalculatorScreenState();
}

class _PercentageCalculatorScreenState extends ConsumerState<PercentageCalculatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(percentageProvider).setSelectedTabIndex(widget.initialTabIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(percentageProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final bgGradientColors = isDarkMode
        ? AppTheme.darkBackgroundGradient
        : AppTheme.lightBackgroundGradient;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Percentage Calc',
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
            tooltip: 'Reset Fields',
            onPressed: provider.reset,
          ),
          SizedBox(width: 8.w),
        ],
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Info
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Finance Tools',
                        style: GoogleFonts.outfit(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
                          letterSpacing: 1,
                        ),
                      ),
                      if (provider.favorites.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14.r,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${provider.favorites.length} Favorited',
                              style: GoogleFonts.outfit(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Tabs Selector
                PercentageTypeTabs(
                  selectedIndex: provider.selectedTabIndex,
                  onTabSelected: provider.setSelectedTabIndex,
                  favorites: provider.favorites,
                  onFavoriteToggled: provider.toggleFavorite,
                ),
                SizedBox(height: 16.h),

                // Inputs Card
                PercentageInputCard(
                  selectedTabIndex: provider.selectedTabIndex,
                  input1Controller: provider.input1Controller,
                  input2Controller: provider.input2Controller,
                  input1Error: provider.input1Error,
                  input2Error: provider.input2Error,
                  isLoading: provider.isLoading,
                  onCalculate: provider.calculate,
                  onReset: provider.reset,
                ),
                SizedBox(height: 16.h),

                // Animated Result Area / Loader
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: provider.isLoading
                      ? _buildLoadingCard(isDarkMode)
                      : provider.calculationResult != null
                          ? PercentageResultCard(
                              key: ValueKey(provider.calculationResult!.createdAt),
                              result: provider.calculationResult!,
                            )
                          : const SizedBox.shrink(),
                ),
                SizedBox(height: 16.h),

                // Session History Card
                PercentageHistoryCard(
                  history: provider.history,
                  onDeleteItem: provider.deleteHistoryItem,
                  onClearAll: provider.clearHistory,
                  onSelectHistoryItem: (item) {
                    provider.loadHistoryItem(item);
                  },
                ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDarkMode) {
    return Card(
      elevation: 0,
      color: isDarkMode ? const Color(0xFF111E38).withOpacity(0.4) : Colors.white.withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(
          color: isDarkMode ? const Color(0xFF334155).withOpacity(0.2) : Colors.black.withOpacity(0.03),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text(
              'Analyzing Percentage Splits...',
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
