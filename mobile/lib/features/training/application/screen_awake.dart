import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keep_screen_on/keep_screen_on.dart';

/// Garde l'écran allumé pendant le lecteur de séance.
abstract interface class ScreenAwake {
  Future<void> keepOn();
  Future<void> release();
}

/// Implémentation native (keep_screen_on ; wakelock_plus est incompatible
/// avec le SDK fixé).
final class DeviceScreenAwake implements ScreenAwake {
  const DeviceScreenAwake();

  @override
  Future<void> keepOn() => KeepScreenOn.turnOn();

  @override
  Future<void> release() => KeepScreenOn.turnOff();
}

final screenAwakeProvider = Provider<ScreenAwake>(
  (ref) => const DeviceScreenAwake(),
);
