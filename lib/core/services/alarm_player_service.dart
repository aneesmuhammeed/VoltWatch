import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:voltwatch/core/constants/app_constants.dart';
import 'package:voltwatch/core/services/logger_service.dart';
import 'package:voltwatch/core/services/notification_service.dart';

class AlarmPlayerService {
  static final AlarmPlayerService _instance = AlarmPlayerService._();
  static AlarmPlayerService get instance => _instance;
  AlarmPlayerService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier<bool>(false);
  StreamSubscription? _playerCompleteSub;

  bool get isPlaying => isPlayingNotifier.value;

  Future<void> initialize() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _playerCompleteSub?.cancel();
      _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
        isPlayingNotifier.value = false;
        LoggerService.instance.info('AlarmPlayerService', 'Playback finished automatically');
      });
      LoggerService.instance.info('AlarmPlayerService', 'Initialized successfully with looping mode');
    } catch (e, stackTrace) {
      LoggerService.instance.error('AlarmPlayerService', 'Failed to initialize', e, stackTrace);
    }
  }

  Future<void> playAlarm({String? soundUrl}) async {
    if (isPlaying) {
      await stopAlarm();
    }
    try {
      final url = soundUrl ?? AppConstants.defaultAlarmSoundUrl;
      LoggerService.instance.info('AlarmPlayerService', 'Starting audible alarm: $url');
      isPlayingNotifier.value = true;
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(UrlSource(url));
      LoggerService.instance.info('AlarmPlayerService', 'Audible alarm playing');
    } catch (e, stackTrace) {
      isPlayingNotifier.value = false;
      LoggerService.instance.error('AlarmPlayerService', 'Failed to play alarm', e, stackTrace);
    }
  }

  Future<void> playPreview(String soundUrl) async {
    try {
      LoggerService.instance.info('AlarmPlayerService', 'Playing preview: $soundUrl');
      await stopAlarm();
      isPlayingNotifier.value = true;
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.play(UrlSource(soundUrl));
    } catch (e, stackTrace) {
      isPlayingNotifier.value = false;
      LoggerService.instance.error('AlarmPlayerService', 'Failed to play preview', e, stackTrace);
    }
  }

  Future<void> stopAlarm() async {
    try {
      LoggerService.instance.info('AlarmPlayerService', 'Stopping audible alarm...');
      await _audioPlayer.stop();
      isPlayingNotifier.value = false;
      await NotificationService.instance.cancelAll();
      LoggerService.instance.info('AlarmPlayerService', 'Audible alarm stopped and system notifications cleared');
    } catch (e, stackTrace) {
      LoggerService.instance.error('AlarmPlayerService', 'Failed to stop alarm', e, stackTrace);
    }
  }

  Future<void> dispose() async {
    await _playerCompleteSub?.cancel();
    await _audioPlayer.dispose();
    isPlayingNotifier.dispose();
  }
}
