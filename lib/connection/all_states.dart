import 'package:android/connection/connect.dart';
import 'package:flutter/foundation.dart';

class AllStates {
  static final ValueNotifier<Map<String, dynamic>> allState = ValueNotifier(_snapshot());
  static bool _isListening = false;

  static void listenAll() {
    if (_isListening) return;
    _isListening = true;

    Connection.isConnected.addListener(_updateAllState);
    Connection.robotRunning.addListener(_updateAllState);
    Connection.livestreamState.addListener(_updateAllState);
    Connection.scanningState.addListener(_updateAllState);
    Connection.robotScanningState.addListener(_updateAllState);
    Connection.performingScan.addListener(_updateAllState);
    Connection.robotLivestream.addListener(_updateAllState);
    Connection.stopCapturingImage.addListener(_updateAllState);
  }

  static void _updateAllState() {
    allState.value = _snapshot();
  }

  static Map<String, dynamic> _snapshot() => {
        "conn": Connection.isConnected.value,
        "robot": Connection.robotRunning.value,
        "live": Connection.livestreamState.value,
        "scan": Connection.scanningState.value,
        "rscan": Connection.robotScanningState.value,
        "performing": Connection.performingScan.value,
        "robotLive": Connection.robotLivestream.value,
        "stopCapture": Connection.stopCapturingImage.value,
      };

  static void dispose() {
    Connection.isConnected.removeListener(_updateAllState);
    Connection.robotRunning.removeListener(_updateAllState);
    Connection.livestreamState.removeListener(_updateAllState);
    Connection.scanningState.removeListener(_updateAllState);
    Connection.robotScanningState.removeListener(_updateAllState);
    Connection.performingScan.removeListener(_updateAllState);
    Connection.robotLivestream.removeListener(_updateAllState);
    Connection.stopCapturingImage.removeListener(_updateAllState);
    _isListening = false;
  }
}
