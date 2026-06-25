import 'package:flutter/material.dart';
import 'package:voltwatch/core/constants/app_constants.dart';

class BatterySaverCard extends StatelessWidget {
  final bool isActive;
  final int currentLevel;

  const BatterySaverCard({
    super.key,
    required this.isActive,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isNearThreshold = currentLevel >= AppConstants.batterySaverThreshold - 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.eco : Icons.eco_outlined,
                  color: isActive ? Colors.green : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Battery Saver',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isActive
                  ? 'Battery at $currentLevel% — consider unplugging to preserve long-term battery health.'
                  : isNearThreshold
                      ? 'Charging past ${AppConstants.batterySaverThreshold}% repeatedly may accelerate battery degradation.'
                      : 'Helps preserve battery health by notifying you at ${AppConstants.batterySaverThreshold}%.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            if (isActive) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: currentLevel / 100,
                minHeight: 4,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
