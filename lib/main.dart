import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/core/providers/providers.dart';
import 'package:voltwatch/core/services/alarm_player_service.dart';
import 'package:voltwatch/core/services/background_service.dart';
import 'package:voltwatch/core/services/home_widget_service.dart';
import 'package:voltwatch/core/services/logger_service.dart';
import 'package:voltwatch/core/services/notification_service.dart';
import 'package:voltwatch/core/theme/app_theme.dart';
import 'package:voltwatch/data/models/battery_health_record.dart';
import 'package:voltwatch/data/models/battery_log.dart';
import 'package:voltwatch/data/models/charging_session.dart';
import 'package:voltwatch/presentation/blocs/analytics/analytics_bloc.dart';
import 'package:voltwatch/presentation/blocs/battery/battery_bloc.dart';
import 'package:voltwatch/presentation/blocs/theme/theme_cubit.dart';
import 'package:voltwatch/presentation/screens/analytics_screen.dart';
import 'package:voltwatch/presentation/screens/dashboard_screen.dart';
import 'package:voltwatch/presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LoggerService.instance.info('App', 'Starting VoltWatch...');

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BatteryLogAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(BatteryHealthRecordAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(ChargingSessionAdapter());
  }
  await Hive.openBox<BatteryLog>(AppConstants.batteryLogBoxName);
  await Hive.openBox<BatteryHealthRecord>(AppConstants.batteryHealthBoxName);
  await Hive.openBox<ChargingSession>(AppConstants.chargingSessionBoxName);
  LoggerService.instance.info('App', 'Hive initialized');

  final sharedPrefs = await SharedPreferences.getInstance();

  await NotificationService.instance.initialize();
  await AlarmPlayerService.instance.initialize();
  await BackgroundService.initialize();
  await BackgroundService.registerPeriodicTask();
  await HomeWidgetService.instance.initialize();
  LoggerService.instance.info('App', 'Services initialized');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const VoltWatchApp(),
    ),
  );
}

class VoltWatchApp extends ConsumerStatefulWidget {
  const VoltWatchApp({super.key});

  @override
  ConsumerState<VoltWatchApp> createState() => _VoltWatchAppState();
}

class _VoltWatchAppState extends ConsumerState<VoltWatchApp> {
  @override
  void initState() {
    super.initState();
    // Start battery monitoring on launch
    ref.read(batteryProvider.notifier).startMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'VoltWatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 700),
      themeAnimationCurve: Curves.fastEaseInToSlowEaseOut,
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  static const _screens = [
    DashboardScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  static const _titles = ['Dashboard', 'Analytics', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            ref.read(analyticsProvider.notifier).refresh();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
