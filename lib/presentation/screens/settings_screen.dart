import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/core/providers/providers.dart';
import 'package:voltwatch/core/services/alarm_player_service.dart';
import 'package:voltwatch/core/services/export_service.dart';
import 'package:voltwatch/core/services/logger_service.dart';
import 'package:voltwatch/presentation/blocs/alert/alert_bloc.dart';
import 'package:voltwatch/presentation/dialogs/export_format_dialog.dart';
import 'package:voltwatch/presentation/blocs/alert/alert_state.dart';
import 'package:voltwatch/presentation/blocs/analytics/analytics_bloc.dart';
import 'package:voltwatch/presentation/blocs/theme/theme_cubit.dart';
import 'package:voltwatch/presentation/widgets/threshold_slider.dart';
import 'package:voltwatch/presentation/widgets/time_picker_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsRepo = ref.watch(settingsRepositoryProvider);
    final alertState = ref.watch(alertProvider);
    final themeMode = ref.watch(themeProvider);
    final analyticsState = ref.watch(analyticsProvider);

    // Listen to error messages
    ref.listen<AlertState>(alertProvider, (previous, current) {
      if (current.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(current.errorMessage!),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    });

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _sectionHeader(context, 'Notifications & Alarms', Icons.notifications_outlined),
        const SizedBox(height: 8),
        if (alertState.isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Battery Alerts'),
                    subtitle: const Text(
                      'Get notified when battery reaches threshold',
                    ),
                    value: alertState.isEnabled,
                    onChanged: (value) {
                      ref.read(alertProvider.notifier).toggleAlerts(value);
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  ThresholdSlider(
                    value: alertState.threshold,
                    enabled: alertState.isEnabled,
                    onChanged: (value) {
                      ref.read(alertProvider.notifier).setThreshold(value);
                    },
                  ),
                  const Divider(height: 24),
                  // Quick presets
                  Text(
                    'Quick Presets',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.quickPresets.map((preset) {
                      final isSelected = alertState.threshold == preset;
                      return FilterChip(
                        label: Text('${AppConstants.presetLabels[preset]} ($preset%)'),
                        selected: isSelected,
                        onSelected: alertState.isEnabled
                            ? (selected) {
                                if (selected) {
                                  ref.read(alertProvider.notifier).setThreshold(preset);
                                }
                              }
                            : null,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        selectedColor: colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Audible Alarm'),
                    subtitle: const Text(
                      'Play a loud alarm sound when threshold is reached',
                    ),
                    secondary: Icon(
                      Icons.alarm,
                      color: alertState.isAlarmEnabled ? Colors.red : colorScheme.onSurfaceVariant,
                    ),
                    value: alertState.isAlarmEnabled,
                    onChanged: (value) {
                      ref.read(alertProvider.notifier).toggleAlarm(value);
                    },
                  ),
                  if (alertState.isAlarmEnabled) ...[
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Alarm Sound',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: alertState.selectedSoundUrl,
                            items: AppConstants.alarmSounds.map((sound) {
                              return DropdownMenuItem<String>(
                                value: sound['url'],
                                child: Text(sound['name']!),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                ref.read(alertProvider.notifier).changeAlarmSound(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ValueListenableBuilder<bool>(
                          valueListenable: AlarmPlayerService.instance.isPlayingNotifier,
                          builder: (context, isPlaying, child) {
                            return IconButton.filledTonal(
                              onPressed: () {
                                if (isPlaying) {
                                  AlarmPlayerService.instance.stopAlarm();
                                } else {
                                  final soundUrl = alertState.selectedSoundUrl;
                                  AlarmPlayerService.instance.playPreview(soundUrl);
                                }
                              },
                              icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                              tooltip: isPlaying ? 'Stop preview' : 'Test sound',
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader(context, 'Daily Summary', Icons.summarize_outlined),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily Battery Summary'),
                  subtitle: const Text('Receive a daily notification with battery stats summary'),
                  value: settingsRepo.isSummaryNotificationEnabled(),
                  onChanged: (value) async {
                    await settingsRepo.setSummaryNotificationEnabled(value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader(context, 'Quiet Hours', Icons.bedtime_outlined),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Quiet Hours'),
                  subtitle: const Text('Mute notifications during sleep time'),
                  value: settingsRepo.isQuietHoursEnabled(),
                  onChanged: (value) async {
                    await settingsRepo.setQuietHoursEnabled(value);
                    setState(() {});
                  },
                ),
                if (settingsRepo.isQuietHoursEnabled()) ...[
                  const Divider(height: 24),
                  TimePickerWidget(
                    initialTime: settingsRepo.getQuietHoursStart(),
                    label: 'Start Time',
                    onTimeChanged: (time) async {
                      await settingsRepo.setQuietHoursStart(time);
                    },
                  ),
                  const SizedBox(height: 8),
                  TimePickerWidget(
                    initialTime: settingsRepo.getQuietHoursEnd(),
                    label: 'End Time',
                    onTimeChanged: (time) async {
                      await settingsRepo.setQuietHoursEnd(time);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader(context, 'Appearance', Icons.palette_outlined),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      themeMode == ThemeMode.dark
                          ? Icons.dark_mode
                          : themeMode == ThemeMode.light
                              ? Icons.light_mode
                              : Icons.brightness_auto,
                      color: themeMode == ThemeMode.dark
                          ? Colors.amber
                          : themeMode == ThemeMode.light
                              ? Colors.orange
                              : colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Theme',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selected) {
                    ref.read(themeProvider.notifier).setThemeMode(selected.first);
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.comfortable,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader(context, 'Data', Icons.storage_outlined),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Export Analytics Data'),
                subtitle: const Text('Save battery logs as CSV, JSON, or PDF'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _exportData(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear Battery History'),
                subtitle: const Text('Remove all logged battery data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmClearData(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionHeader(context, 'About', Icons.info_outline),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.bolt, color: colorScheme.primary),
                ),
                title: const Text('VoltWatch'),
                subtitle: const Text('v1.0.0 • Battery Management & Analytics'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Logging Interval'),
                subtitle: Text('Every ${AppConstants.logInterval.inMinutes} minutes'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Total Logs'),
                subtitle: Text('${analyticsState.logs.length} entries'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final state = ref.read(analyticsProvider);
    final logs = state.logs;

    if (logs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No logs available to export.')),
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ExportFormatDialog(),
    );

    if (result == null || !context.mounted) return;

    final format = result['format'] as String;
    final includeStats = result['includeStats'] as bool;

    try {
      ExportResult exportResult;
      if (format == 'pdf') {
        exportResult = await ExportService.exportToPdf(
          logs: logs,
          insights: state.insights,
          includeStats: includeStats,
        );
      } else if (format == 'json') {
        exportResult = await ExportService.exportToJson(
          logs: logs,
          insights: state.insights,
          includeStats: includeStats,
        );
      } else {
        exportResult = await ExportService.exportToCsv(
          logs: logs,
          insights: state.insights,
          includeStats: includeStats,
        );
      }

      if (context.mounted) {
        await ExportService.shareFile(exportResult);
      }
    } catch (e) {
      LoggerService.instance.error('SettingsScreen', 'Export failed', e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export data.')),
        );
      }
    }
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will permanently delete all battery logs. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(analyticsProvider.notifier).clearAll();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Battery history cleared')),
              );
              LoggerService.instance.info('SettingsScreen', 'History cleared');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
