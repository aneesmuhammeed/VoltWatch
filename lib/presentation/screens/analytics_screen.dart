import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voltwatch/presentation/blocs/analytics/analytics_bloc.dart';
import 'package:voltwatch/presentation/widgets/battery_chart.dart';
import 'package:voltwatch/presentation/widgets/battery_insights_card.dart';
import 'package:voltwatch/presentation/widgets/battery_log_tile.dart';
import 'package:voltwatch/presentation/widgets/charging_session_tile.dart';
import 'package:voltwatch/presentation/widgets/drain_comparison_card.dart';
import 'package:voltwatch/presentation/dialogs/export_format_dialog.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/core/services/export_service.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  Future<void> _showExportDialog(BuildContext context, WidgetRef ref) async {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export data.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No battery logs yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
             Text(
              'Data is logged every ${AppConstants.logInterval.inMinutes} minutes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(analyticsProvider.notifier).refresh();
      },
      child: CustomScrollView(
        slivers: [
          // Chart section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Battery History',
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 8),
                  BatteryChart(logs: state.logs),
                ],
              ),
            ),
          ),

          // Drain comparison card
          if (state.screenOnDrainPerHour != null && state.bgDrainPerHour != null)
            SliverToBoxAdapter(
              child: DrainComparisonCard(
                screenOnDrain: state.screenOnDrainPerHour!,
                bgDrain: state.bgDrainPerHour!,
              ),
            ),

          // Insights card
          if (state.insights != null)
            SliverToBoxAdapter(
              child: BatteryInsightsCard(insights: state.insights!),
            ),

          // Charging sessions header
          if (state.chargingSessions.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Charging Sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

          // Charging sessions list
          if (state.chargingSessions.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => ChargingSessionTile(session: state.chargingSessions[index]),
                  childCount: state.chargingSessions.length > 5 ? 5 : state.chargingSessions.length,
                ),
              ),
            ),

          // Log list header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Logs',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${state.logs.length} entries',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_outlined),
                    tooltip: 'Export data',
                    onPressed: () => _showExportDialog(context, ref),
                  ),
                ],
              ),
            ),
          ),

          // Log list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final displayedLogs = state.logs.take(state.displayedLogCount).toList();
                if (index >= displayedLogs.length) return null;
                return BatteryLogTile(log: displayedLogs[index]);
              },
              childCount: state.logs.length.clamp(0, state.displayedLogCount),
            ),
          ),

          // Load more button
          if (state.logs.length > state.displayedLogCount)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: FilledButton.tonal(
                    onPressed: () => ref.read(analyticsProvider.notifier).loadMoreLogs(),
                    child: Text('Load more (${state.logs.length - state.displayedLogCount} remaining)'),
                  ),
                ),
              ),
            ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}
