import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/presentation/blocs/battery/battery_bloc.dart';
import 'package:voltwatch/presentation/widgets/battery_gauge.dart';

import 'package:voltwatch/presentation/widgets/battery_saver_card.dart';
import 'package:voltwatch/presentation/widgets/battery_state_chip.dart';
import 'package:voltwatch/presentation/widgets/health_degradation_card.dart';
import 'package:voltwatch/presentation/widgets/quick_stats_card.dart';
import 'package:voltwatch/presentation/widgets/temperature_indicator.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(batteryProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(batteryProvider.notifier).startMonitoring(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          BatteryGauge(level: state.level, isCharging: state.isCharging, size: 220),
          const SizedBox(height: 16),
          BatteryStateChip(batteryState: state.state),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [

                // Temperature
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TemperatureIndicator(temperatureCelsius: state.temperatureCelsius),
                ),

                // Health degradation
                HealthDegradationCard(
                  healthPercent: state.healthPercent,
                  chargeCycleCount: state.chargeCycleCount,
                ),
                const SizedBox(height: 16),

                // Battery Saver Card
                if (state.batterySaverEnabled)
                  BatterySaverCard(
                    isActive: state.batterySaverActive,
                    currentLevel: state.level,
                  ),
                if (state.batterySaverEnabled)
                  const SizedBox(height: 16),

                // Quick stats card
                const QuickStatsCard(),
                const SizedBox(height: 16),

                // Estimated time to full
                if (state.isCharging && state.estimatedMinutesToFull != null)
                  _buildInfoCard(
                    context,
                    icon: Icons.timer_outlined,
                    title: 'Estimated Time to Full',
                    value: _formatMinutes(state.estimatedMinutesToFull!),
                    color: AppConstants.batteryHighColor,
                  ),
                if (state.isCharging && state.estimatedMinutesToFull != null)
                  const SizedBox(height: 8),

                // Detail card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDetailRow(context, 'Battery Level', '${state.level}%', Icons.battery_std),
                        const Divider(height: 24),
                        _buildDetailRow(context, 'Status', state.state, Icons.info_outline),
                        if (state.isFull) ...[
                          const Divider(height: 24),
                          _buildDetailRow(context, 'Health', 'Fully Charged', Icons.check_circle_outline),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String title, required String value, required Color color}) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}
