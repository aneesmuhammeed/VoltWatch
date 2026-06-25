import 'package:flutter/services.dart';
import 'package:voltwatch/core/services/logger_service.dart';

class BatteryTemperatureService {
  static const _channel = MethodChannel('com.gurucool.voltwatch/battery');

  static Future<double?> getTemperature() async {
    try {
      final temp = await _channel.invokeMethod<double>('getBatteryTemperature');
      return temp;
    } catch (e) {
      LoggerService.instance.debug('BatteryTemperature', 'Temperature not available: $e');
      return null;
    }
  }
}
