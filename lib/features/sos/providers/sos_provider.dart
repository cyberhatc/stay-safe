import 'package:flutter_riverpod/flutter_riverpod.dart';

class SosState {
  final bool isTriggered;

  SosState({this.isTriggered = false});

  SosState copyWith({bool? isTriggered}) {
    return SosState(isTriggered: isTriggered ?? this.isTriggered);
  }
}

final sosStateProvider = NotifierProvider<SosNotifier, SosState>(SosNotifier.new);

class SosNotifier extends Notifier<SosState> {
  @override
  SosState build() {
    return SosState();
  }

  void trigger() {
    state = state.copyWith(isTriggered: true);
  }

  void reset() {
    state = SosState();
  }
}
