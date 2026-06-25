import 'dart:math';
import 'package:flutter/material.dart';
import 'package:voltwatch/core/constants/app_constants.dart';

/// Animated circular battery gauge using CustomPainter.
/// Shows battery level as a sweeping arc with dynamic color.
class BatteryGauge extends StatefulWidget {
  final int level;
  final bool isCharging;
  final double size;

  const BatteryGauge({
    super.key,
    required this.level,
    this.isCharging = false,
    this.size = 200,
  });

  @override
  State<BatteryGauge> createState() => _BatteryGaugeState();
}

class _BatteryGaugeState extends State<BatteryGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousLevel = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.level.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(BatteryGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _previousLevel = _animation.value;
      _animation = Tween<double>(
        begin: _previousLevel,
        end: widget.level.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animatedLevel = _animation.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _GaugePainter(
              level: animatedLevel,
              trackColor: colorScheme.surfaceContainerHighest,
              gaugeColor: AppConstants.batteryColor(animatedLevel.round()),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isCharging)
                    Icon(
                      Icons.bolt,
                      color: AppConstants.batteryColor(animatedLevel.round()),
                      size: widget.size * 0.12,
                    ),
                  Text(
                    '${animatedLevel.round()}%',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.batteryColor(animatedLevel.round()),
                        ),
                  ),
                  Text(
                    'Battery',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double level;
  final Color trackColor;
  final Color gaugeColor;

  _GaugePainter({
    required this.level,
    required this.trackColor,
    required this.gaugeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;
    const strokeWidth = 14.0;
    const startAngle = 135 * (pi / 180); // start from bottom-left
    const totalSweep = 270 * (pi / 180); // 270-degree arc

    // Background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // Foreground gauge
    final gaugePaint = Paint()
      ..color = gaugeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = totalSweep * (level / 100).clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      gaugePaint,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) =>
      oldDelegate.level != level || oldDelegate.gaugeColor != gaugeColor;
}
