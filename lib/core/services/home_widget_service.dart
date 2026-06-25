import 'package:home_widget/home_widget.dart';
import 'package:voltwatch/data/repositories/settings_repository.dart';
import 'package:voltwatch/presentation/blocs/battery/battery_state.dart';

class HomeWidgetService {
  static final HomeWidgetService _instance = HomeWidgetService._();
  static HomeWidgetService get instance => _instance;
  HomeWidgetService._();

  Future<void> initialize() async {
    // Widget interactivity callback can be registered here if needed
  }

  Future<void> updateWidget(BatteryState state, SettingsRepository settingsRepo) async {
    try {
      await HomeWidget.saveWidgetData<int>('battery_level', state.level);
      await HomeWidget.saveWidgetData<String>('battery_state', state.state);
      await HomeWidget.saveWidgetData<bool>('is_charging', state.isCharging);
      await HomeWidget.saveWidgetData<int?>('estimated_minutes', state.estimatedMinutesToFull);
      await HomeWidget.saveWidgetData<double?>('temperature', state.temperatureCelsius);
      await HomeWidget.updateWidget(
        name: 'BatteryWidget',
        iOSName: 'BatteryWidget',
      );
    } catch (e) {
      // Widget not available (e.g., no home screen widget placed)
    }
  }
}
