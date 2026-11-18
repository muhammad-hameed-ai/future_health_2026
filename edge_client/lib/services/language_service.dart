import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';

/// Centralized Language Coordinator for SkinGuard UAE.
/// Emits reactive updates across the entire application hierarchy.
class LanguageService {
  static final ValueNotifier<bool> isArabicNotifier = ValueNotifier<bool>(false);

  static bool get isArabic => isArabicNotifier.value;

  /// Loads saved language preference on app startup
  static Future<void> init() async {
    try {
      final saved = await LocalStorageService.getSavedLanguage();
      if (saved != null) {
        isArabicNotifier.value = (saved == 'ar');
      }
    } catch (_) {}
  }

  /// Sets global language and persists selection
  static void setLanguage({required bool arabic}) {
    if (isArabicNotifier.value != arabic) {
      isArabicNotifier.value = arabic;
      LocalStorageService.saveLanguagePreference(arabic ? 'ar' : 'en');
    }
  }

  /// Toggles between English and Arabic globally
  static void toggleLanguage() {
    setLanguage(arabic: !isArabicNotifier.value);
  }
}
