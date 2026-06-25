import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voltwatch/core/providers/providers.dart';
import 'package:voltwatch/data/repositories/settings_repository.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  late final SettingsRepository _settingsRepo;

  @override
  ThemeMode build() {
    _settingsRepo = ref.watch(settingsRepositoryProvider);
    final saved = _settingsRepo.getThemeMode();
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    String modeStr;
    switch (mode) {
      case ThemeMode.light:
        modeStr = 'light';
        break;
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
    }
    await _settingsRepo.setThemeMode(modeStr);
    state = mode;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
