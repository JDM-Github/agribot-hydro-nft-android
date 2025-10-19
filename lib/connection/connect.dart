import 'package:android/utils/struct.dart';
import 'package:flutter/foundation.dart';
import 'socketio.dart';

class Connection {
  // Reactive states
  static final ValueNotifier<bool> isConnected = ValueNotifier(false);
  static final ValueNotifier<int> robotRunning = ValueNotifier(0);
  static final ValueNotifier<int> livestreamState = ValueNotifier(0);
  static final ValueNotifier<bool> scanningState = ValueNotifier(false);
  static final ValueNotifier<bool> robotScanningState = ValueNotifier(false);
  static final ValueNotifier<bool> stopCapturingImage = ValueNotifier(false);
  static final ValueNotifier<bool> robotLivestream = ValueNotifier(false);
  static final ValueNotifier<bool> performingScan = ValueNotifier(false);

  static final ValueNotifier<Map<String, dynamic>> tcrt5000 = ValueNotifier({"left": false, "right": false});
  static final ValueNotifier<List<bool>> waterReadings = ValueNotifier([false, false, false, false]);
  static final ValueNotifier<Map<String, dynamic>> tcs34725 = ValueNotifier({
    "raw": {"r": 0, "g": 0, "b": 0, "c": 0},
    "normalized": {"r": 0, "g": 0, "b": 0},
    "color_name": "NOT SET"
  });
  static final ValueNotifier<num> ultrasonic = ValueNotifier(0);

  static final ValueNotifier<Uint8List?> scanFrame = ValueNotifier(null);
  static final ValueNotifier<Uint8List?> liveFrame = ValueNotifier(null);
  static final ValueNotifier<Uint8List?> robotLiveFrame = ValueNotifier(null);

  static final ValueNotifier<List<dynamic>> latestResults = ValueNotifier([]);
  static final ValueNotifier<PlantHistories> plantHistories = ValueNotifier([]);
  static final ValueNotifier<List<String>> logs = ValueNotifier([]);

  static bool parseBool(dynamic data) {
    if (data is bool) return data;
    if (data is num) return data != 0;
    if (data is String) return data == 'true' || data == '1';
    return false;
  }


  static void init() {
    SocketService.init();
    final socket = SocketService.socket;
    if (socket == null) return;

    socket.on('connect', (_) {
      isConnected.value = true;
    });

    socket.on('disconnect', (_) {
      _resetStates();
    });

    socket.on('connect_error', (err) {
      _resetStates();
    });

    socket.on('tcrt5000', (data) => tcrt5000.value = Map<String, dynamic>.from(data));
    socket.on('waterSensors', (data) {
      final readings = List<bool>.from(
        (data as List).map((e) => e == 1 || e == true),
      );
      Connection.waterReadings.value = readings;
    });
    socket.on('tcs34725', (data) {
      tcs34725.value = Map<String, dynamic>.from(data);
    });
    socket.on('ultrasonic', (data) => ultrasonic.value = data);

    socket.on('robot-running', (data) => robotRunning.value = data is int ? data : 0);
    socket.on('livestream-state', (data) => livestreamState.value = data is int ? data : 0);
    socket.on('scanning-state', (data) => scanningState.value = parseBool(data));
    socket.on('robot-scanning-state', (data) => robotScanningState.value = parseBool(data));
    socket.on('stop-capturing-image', (data) => stopCapturingImage.value = parseBool(data));
    socket.on('performing-scan', (data) => performingScan.value = parseBool(data));
    socket.on('robot-livestream', (data) {
      final boolValue = parseBool(data);
      if (robotLivestream.value != boolValue) {
        robotLivestream.value = boolValue;
      }
    });



    // // Frames
    socket.on('livestream_frame', (data) => liveFrame.value = Uint8List.fromList(data));
    socket.on('livestream_frame_stop', (data) => liveFrame.value = null);
    socket.on('robot_livestream_frame', (data) => robotLiveFrame.value = Uint8List.fromList(data));
    socket.on('robot_livestream_frame_stop', (data) => robotLiveFrame.value = null);
    socket.on('logs', (data) {
      if (data['logs'] != null) {
        logs.value = [...logs.value, ...List<String>.from(data['logs'])].take(300).toList();
      }
    });

    socket.on('plant-histories', (data) {
      final incoming = List<Map<String, dynamic>>.from(data).map((e) {
        e['id'] ??= 'plant-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
        return PlantHistory.fromJson(e);
      }).toList();

      final combined = [...incoming, ...plantHistories.value];
      final unique = <String, PlantHistory>{};
      for (final item in combined) {
        final key = '${item.src}_${item.timestamp}';
        unique[key] = item;
      }
      plantHistories.value = unique.values.take(6).toList();
    });

  }

  static void emitSetLogDate(String date) {
    SocketService.emit("set_log_date", {date: date});
  }

  static void connect() {
    final socket = SocketService.socket;
    if (socket == null) return;
    if (!socket.connected) socket.connect();
  }

  static void disconnect() {
    SocketService.disconnect();
    _resetStates();
  }

  static void _resetStates() {
    isConnected.value = false;
    robotRunning.value = 0;
    livestreamState.value = 0;
    scanningState.value = false;
    robotScanningState.value = false;
    stopCapturingImage.value = false;
    robotLivestream.value = false;
    performingScan.value = false;

    scanFrame.value = null;
    liveFrame.value = null;
    robotLiveFrame.value = null;
    latestResults.value = [];
    logs.value = [];
  }
}
