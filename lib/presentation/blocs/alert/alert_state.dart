class AlertState {
  final int threshold;
  final bool isEnabled;
  final bool isLoading;
  final bool isAlarmEnabled;
  final String selectedSoundUrl;
  final String? errorMessage;
  final int errorNonce;

  static const String _defaultSoundUrl =
      'https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg';

  const AlertState({
    this.threshold = 80,
    this.isEnabled = true,
    this.isLoading = true,
    this.isAlarmEnabled = false,
    this.selectedSoundUrl = AlertState._defaultSoundUrl,
    this.errorMessage,
    this.errorNonce = 0,
  });

  AlertState copyWith({
    int? threshold,
    bool? isEnabled,
    bool? isLoading,
    bool? isAlarmEnabled,
    String? selectedSoundUrl,
    String? errorMessage,
    int? errorNonce,
  }) {
    return AlertState(
      threshold: threshold ?? this.threshold,
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      isAlarmEnabled: isAlarmEnabled ?? this.isAlarmEnabled,
      selectedSoundUrl: selectedSoundUrl ?? this.selectedSoundUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      errorNonce: errorNonce ?? this.errorNonce,
    );
  }
}
