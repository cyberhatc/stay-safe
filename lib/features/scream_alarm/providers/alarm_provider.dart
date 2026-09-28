import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlarmState {
  final bool isPlaying;

  AlarmState({this.isPlaying = false});

  AlarmState copyWith({bool? isPlaying}) {
    return AlarmState(isPlaying: isPlaying ?? this.isPlaying);
  }
}

final alarmStateProvider = NotifierProvider<AlarmNotifier, AlarmState>(
  AlarmNotifier.new,
);

class AlarmNotifier extends Notifier<AlarmState> {
  @override
  AlarmState build() {
    return AlarmState();
  }

  void setPlaying(bool playing) {
    state = state.copyWith(isPlaying: playing);
  }

  void toggle() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }
}
