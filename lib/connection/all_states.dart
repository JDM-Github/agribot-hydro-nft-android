import 'package:android/connection/connect.dart';
import 'package:flutter/foundation.dart';

class AllStates {
  static final ValueNotifier<Map<String, dynamic>> allState = ValueNotifier(_snapshot());
  static bool _isListening = false;

  static void listenAll() {
    if (_isListening) return;
    _isListening = true;

    Connection.isConnected.addListener(updateAllState);
    Connection.robotRunning.addListener(updateAllState);
    Connection.livestreamState.addListener(updateAllState);
    Connection.scanningState.addListener(updateAllState);
    Connection.robotScanningState.addListener(updateAllState);
    Connection.performingScan.addListener(updateAllState);
    Connection.robotLivestream.addListener(updateAllState);
    Connection.stopCapturingImage.addListener(updateAllState);
  }

  static void updateAllState() {
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
    Connection.isConnected.removeListener(updateAllState);
    Connection.robotRunning.removeListener(updateAllState);
    Connection.livestreamState.removeListener(updateAllState);
    Connection.scanningState.removeListener(updateAllState);
    Connection.robotScanningState.removeListener(updateAllState);
    Connection.performingScan.removeListener(updateAllState);
    Connection.robotLivestream.removeListener(updateAllState);
    Connection.stopCapturingImage.removeListener(updateAllState);
    _isListening = false;
  }
}
