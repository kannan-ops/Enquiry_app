import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enquiry_app/services/storage_service.dart';
import 'package:enquiry_app/services/auth_service.dart';
import 'package:enquiry_app/theme/theme_provider.dart';
import 'package:enquiry_app/services/sound_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.currentInstance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(storageServiceProvider));
});

final themeProvider = ChangeNotifierProvider<ThemeProvider>((ref) {
  return ThemeProvider(ref.watch(storageServiceProvider));
});

final notificationSoundServiceProvider = Provider<NotificationSoundService>((ref) {
  return NotificationSoundService();
});
