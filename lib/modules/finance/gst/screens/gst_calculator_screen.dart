import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme/app_theme.dart';
import '../providers/gst_provider.dart';
import '../widgets/gst_type_tabs.dart';
import '../widgets/gst_input_card.dart';
import '../widgets/gst_result_card.dart';
import '../widgets/gst_history_card.dart';

class GstCalculatorScreen extends ConsumerWidget {
  const GstCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(gstProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final bgGradientColors = isDarkMode 
        ? AppTheme.darkBackgroundGradient 
        : AppTheme.lightBackgroundGradient;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'GST Calculator',
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
              tooltip: 'Reset Fields',
              onPressed: provider.reset,
            ),
          ),
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
                  child: Text(
                    'Finance Tools',
                    style: GoogleFonts.outfit(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                
                // GST Tabs
                GstTypeTabs(
                  selectedIndex: provider.selectedTypeIndex,
                  onTabSelected: provider.setSelectedTypeIndex,
                ),
                SizedBox(height: 16.h),

                // Main Input Card
                GstInputCard(
                  amountController: provider.amountController,
                  selectedGstRate: provider.selectedGstPercentage,
                  onGstRateChanged: provider.setGstPercentage,
                  validationError: provider.validationError,
                  isLoading: provider.isLoading,
                  onCalculate: provider.calculate,
                  onReset: provider.reset,
                  selectedTab: provider.selectedTypeIndex,
                ),
                SizedBox(height: 16.h),

                // Animated Result Area
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: provider.isLoading
                      ? _buildLoadingCard(isDarkMode)
                      : provider.calculationResult != null
                          ? GstResultCard(
                              key: ValueKey(provider.calculationResult!.createdAt),
                              result: provider.calculationResult!,
                            )
                          : const SizedBox.shrink(),
                ),
                SizedBox(height: 16.h),

                // Session History Card
                GstHistoryCard(
                  history: provider.history,
                  onDeleteItem: provider.deleteHistoryItem,
                  onClearAll: provider.clearHistory,
                  onSelectHistoryItem: (item) {
                    provider.loadHistoryItem(item);
                    // Optionally scroll up to results
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
              'Computing Breakdowns...',
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
