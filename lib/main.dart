import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enquiry_app/services/storage_service.dart';
import 'package:enquiry_app/theme/app_theme.dart';
import 'package:enquiry_app/screens/dashboard_screen.dart';
import 'package:enquiry_app/providers/riverpod_providers.dart';
import 'package:enquiry_app/utils/sharing_intent_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Pre-load storage asynchronously in background without blocking runApp
  StorageService.getInstance();

  runApp(
    const ProviderScope(
      child: CircuitPointApp(),
    ),
  );
}

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void navigateToLogin() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false,
    );
  }

  static void navigateToDashboard() {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
      (route) => false,
    );
  }
}

class CircuitPointApp extends ConsumerStatefulWidget {
  const CircuitPointApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CircuitPointAppState();
}

class _CircuitPointAppState extends ConsumerState<CircuitPointApp> {
  @override
  void initState() {
    super.initState();
    SharingIntentHandler.init();
  }

  @override
  void dispose() {
    SharingIntentHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final themeProviderVal = ref.watch(themeProvider);

        return MaterialApp(
          title: 'CircuitPoint',
          navigatorKey: NavigationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: themeProviderVal.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
